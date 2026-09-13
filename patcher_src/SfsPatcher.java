package build.bytes.sfs;

import com.android.tools.smali.dexlib2.AccessFlags;
import com.android.tools.smali.dexlib2.DexFileFactory;
import com.android.tools.smali.dexlib2.Opcode;
import com.android.tools.smali.dexlib2.Opcodes;
import com.android.tools.smali.dexlib2.iface.ClassDef;
import com.android.tools.smali.dexlib2.iface.DexFile;
import com.android.tools.smali.dexlib2.iface.Method;
import com.android.tools.smali.dexlib2.iface.MethodImplementation;
import com.android.tools.smali.dexlib2.iface.MethodParameter;
import com.android.tools.smali.dexlib2.iface.MultiDexContainer;
import com.android.tools.smali.dexlib2.iface.instruction.Instruction;
import com.android.tools.smali.dexlib2.immutable.ImmutableMethod;
import com.android.tools.smali.dexlib2.immutable.ImmutableMethodImplementation;
import com.android.tools.smali.dexlib2.immutable.instruction.*;
import com.android.tools.smali.dexlib2.immutable.reference.ImmutableMethodReference;
import com.android.tools.smali.dexlib2.immutable.reference.ImmutableTypeReference;
import com.android.tools.smali.dexlib2.rewriter.*;

import java.io.*;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.zip.Deflater;
import java.util.zip.ZipEntry;
import java.util.zip.ZipFile;
import java.util.zip.ZipOutputStream;

public class SfsPatcher {

    public enum PatchAction {
        RETURN_TRUE,
        RETURN_FALSE,
        RETURN_LIST,
        RETURN_VOID
    }

    private static final Map<String, PatchAction> SERVICES_PRESET = new HashMap<>();

    static {
        // Core FLAG_SECURE & Anti-detection rules (Android 10-17 + OEMs)
        SERVICES_PRESET.put("isSecureLocked", PatchAction.RETURN_FALSE);          // WindowState
        SERVICES_PRESET.put("hasSecureWindowOnScreen", PatchAction.RETURN_FALSE); // DisplayContent
        SERVICES_PRESET.put("notifyScreenshotListeners", PatchAction.RETURN_LIST);  // A14+ Anti-detection
        SERVICES_PRESET.put("canBeScreenshotTarget", PatchAction.RETURN_TRUE);    // RootWindowContainer
        SERVICES_PRESET.put("notAllowCaptureDisplay", PatchAction.RETURN_FALSE);  // Xiaomi HyperOS/MIUI
        SERVICES_PRESET.put("hasSecure", PatchAction.RETURN_FALSE);               // OPPO/OnePlus/Realme
    }

    public static void main(String[] args) {
        long startTime = System.currentTimeMillis();
        if (args.length < 2) {
            System.err.println("Usage: SfsPatcher <input.jar> <output.jar> [services] [--patch method=true|false|list|void ...]");
            System.exit(1);
        }

        File inputFile = new File(args[0]);
        File outputFile = new File(args[1]);
        Map<String, PatchAction> patchRules = new HashMap<>(SERVICES_PRESET);

        int argIndex = 2;
        if (args.length > 2 && !args[2].startsWith("--")) {
            argIndex = 3;
        }

        for (int i = argIndex; i < args.length; i++) {
            if (args[i].startsWith("--patch")) {
                String val = (i + 1 < args.length && !args[i + 1].startsWith("--")) ? args[++i] : args[i].substring("--patch".length()).trim();
                if (val.startsWith("=")) val = val.substring(1);
                String[] parts = val.split("=", 2);
                if (parts.length == 2) {
                    String methodName = parts[0].trim();
                    String act = parts[1].trim().toLowerCase();
                    if ("true".equals(act) || "1".equals(act)) patchRules.put(methodName, PatchAction.RETURN_TRUE);
                    else if ("false".equals(act) || "0".equals(act)) patchRules.put(methodName, PatchAction.RETURN_FALSE);
                    else if ("list".equals(act)) patchRules.put(methodName, PatchAction.RETURN_LIST);
                    else if ("void".equals(act)) patchRules.put(methodName, PatchAction.RETURN_VOID);
                }
            }
        }

        System.out.println("⚡ SFS Parallel DEX Patcher (dexlib2)");
        System.out.println("📁 Target: " + inputFile.getName() + " (" + patchRules.size() + " essential rules)");

        try {
            boolean success = patchJarParallel(inputFile, outputFile, patchRules);
            if (!success) {
                System.err.println("❌ Patching failed or no target methods were modified!");
                System.exit(2);
            }
            long elapsed = System.currentTimeMillis() - startTime;
            System.out.println("✨ All done in " + (elapsed / 1000.0) + "s!");
            System.exit(0);
        } catch (Exception e) {
            System.err.println("💥 Fatal error during patching: " + e.getMessage());
            e.printStackTrace();
            System.exit(1);
        }
    }

    private static boolean patchJarParallel(File inputFile, File outputFile, Map<String, PatchAction> patchRules) throws Exception {
        long phaseStart = System.currentTimeMillis();
        Opcodes opcodes = Opcodes.getDefault();
        MultiDexContainer<? extends DexFile> container = DexFileFactory.loadDexContainer(inputFile, opcodes);
        List<String> entryNames = container.getDexEntryNames();

        if (entryNames.isEmpty()) {
            throw new IOException("No DEX entries found in " + inputFile.getName());
        }

        Map<String, File> modifiedDexFiles = new ConcurrentHashMap<>();
        AtomicInteger totalPatchedMethods = new AtomicInteger(0);
        List<String> patchSummary = Collections.synchronizedList(new ArrayList<>());

        entryNames.parallelStream().forEach(entryName -> {
            try {
                DexFile origDex = container.getEntry(entryName).getDexFile();

                boolean hasTarget = false;
                for (ClassDef classDef : origDex.getClasses()) {
                    String classType = classDef.getType();
                    if (!classType.startsWith("Lcom/android/server/") &&
                        !classType.startsWith("Lcom/miui/") &&
                        !classType.startsWith("Lcom/oplus/") &&
                        !classType.startsWith("Lcom/samsung/")) {
                        continue;
                    }
                    for (Method method : classDef.getMethods()) {
                        if (patchRules.containsKey(method.getName())) {
                            hasTarget = true;
                            break;
                        }
                    }
                    if (hasTarget) break;
                }

                if (!hasTarget) {
                    return;
                }

                List<String> patchedDetails = new ArrayList<>();
                DexRewriter rewriter = new DexRewriter(new RewriterModule() {
                    @Override
                    public Rewriter<ClassDef> getClassDefRewriter(Rewriters rewriters) {
                        return new ClassDefRewriter(rewriters) {
                            @Override
                            public ClassDef rewrite(ClassDef classDef) {
                                String type = classDef.getType();
                                if (!type.startsWith("Lcom/android/server/") &&
                                    !type.startsWith("Lcom/miui/") &&
                                    !type.startsWith("Lcom/oplus/") &&
                                    !type.startsWith("Lcom/samsung/")) {
                                    return classDef;
                                }
                                return super.rewrite(classDef);
                            }
                        };
                    }

                    @Override
                    public Rewriter<Method> getMethodRewriter(Rewriters rewriters) {
                        return new MethodRewriter(rewriters) {
                            @Override
                            public Method rewrite(Method method) {
                                String name = method.getName();
                                PatchAction action = patchRules.get(name);
                                if (action != null) {
                                    int flags = method.getAccessFlags();
                                    // Skip abstract/native to prevent ART verify errors (bootloops)
                                    if ((flags & AccessFlags.ABSTRACT.getValue()) != 0 ||
                                        (flags & AccessFlags.NATIVE.getValue()) != 0) {
                                        return super.rewrite(method);
                                    }
                                    MethodImplementation newImpl = buildImplementation(method, action);
                                    patchedDetails.add(method.getDefiningClass() + "->" + name + "() [" + action + "]");
                                    return new ImmutableMethod(
                                            method.getDefiningClass(),
                                            method.getName(),
                                            method.getParameters(),
                                            method.getReturnType(),
                                            method.getAccessFlags(),
                                            method.getAnnotations(),
                                            method.getHiddenApiRestrictions(),
                                            newImpl
                                    );
                                }
                                return super.rewrite(method);
                            }
                        };
                    }
                });

                DexFile rewrittenDex = rewriter.getDexFileRewriter().rewrite(origDex);

                File outDir = outputFile.getParentFile();
                if (outDir == null) outDir = new File(".");
                outDir.mkdirs();
                File tempDex = File.createTempFile("sfs_" + entryName.replace(".dex", "") + "_", ".dex", outDir);
                tempDex.deleteOnExit();
                DexFileFactory.writeDexFile(tempDex.getAbsolutePath(), rewrittenDex);
                modifiedDexFiles.put(entryName, tempDex);
                totalPatchedMethods.addAndGet(patchedDetails.size());

                for (String detail : patchedDetails) {
                    patchSummary.add(entryName + " -> " + detail);
                }
            } catch (Exception e) {
                throw new RuntimeException("Error processing " + entryName, e);
            }
        });

        if (totalPatchedMethods.get() == 0) {
            System.out.println("⚠️ Warning: No target methods matched in any DEX file!");
            return false;
        }

        for (String line : patchSummary) {
            System.out.println("   ✓ " + line);
        }

        long patchDuration = System.currentTimeMillis() - phaseStart;
        System.out.println("⏱️ Bytecode patched in " + (patchDuration / 1000.0) + "s");

        long repackStart = System.currentTimeMillis();
        System.out.println("🖇️ Repacking archive (updating " + modifiedDexFiles.size() + " DEX file(s))...");
        if (outputFile.getParentFile() != null) {
            outputFile.getParentFile().mkdirs();
        }

        try (ZipFile zipIn = new ZipFile(inputFile);
             ZipOutputStream zos = new ZipOutputStream(new BufferedOutputStream(new FileOutputStream(outputFile), 65536))) {

            zos.setLevel(Deflater.BEST_SPEED);
            Enumeration<? extends ZipEntry> entries = zipIn.entries();
            while (entries.hasMoreElements()) {
                ZipEntry entry = entries.nextElement();
                String name = entry.getName();

                if (modifiedDexFiles.containsKey(name)) {
                    File patchedDex = modifiedDexFiles.get(name);
                    ZipEntry newEntry = new ZipEntry(name);
                    newEntry.setTime(System.currentTimeMillis());
                    zos.putNextEntry(newEntry);
                    try (InputStream fis = new BufferedInputStream(new FileInputStream(patchedDex), 65536)) {
                        copyStream(fis, zos);
                    }
                    zos.closeEntry();
                    patchedDex.delete();
                } else {
                    ZipEntry newEntry = new ZipEntry(name);
                    newEntry.setTime(entry.getTime());
                    if (entry.getMethod() == ZipEntry.STORED) {
                        newEntry.setMethod(ZipEntry.STORED);
                        newEntry.setSize(entry.getSize());
                        newEntry.setCompressedSize(entry.getCompressedSize());
                        newEntry.setCrc(entry.getCrc());
                    }
                    zos.putNextEntry(newEntry);
                    try (InputStream is = zipIn.getInputStream(entry)) {
                        copyStream(is, zos);
                    }
                    zos.closeEntry();
                }
            }
        }

        long repackDuration = System.currentTimeMillis() - repackStart;
        System.out.println("⏱️ Repack completed in " + (repackDuration / 1000.0) + "s");

        return true;
    }

    private static MethodImplementation buildImplementation(Method method, PatchAction action) {
        boolean isStatic = (method.getAccessFlags() & AccessFlags.STATIC.getValue()) != 0;
        int paramRegs = isStatic ? 0 : 1;
        for (MethodParameter param : method.getParameters()) {
            String type = param.getType();
            if ("J".equals(type) || "D".equals(type)) {
                paramRegs += 2;
            } else {
                paramRegs += 1;
            }
        }
        int totalRegisters = Math.max(1, paramRegs + 1);

        List<Instruction> instructions = new ArrayList<>();
        String retType = method.getReturnType();

        if ("V".equals(retType) || action == PatchAction.RETURN_VOID) {
            instructions.add(new ImmutableInstruction10x(Opcode.RETURN_VOID));
        } else if (action == PatchAction.RETURN_LIST && (retType.startsWith("L") || retType.startsWith("["))) {
            instructions.add(new ImmutableInstruction21c(Opcode.NEW_INSTANCE, 0, new ImmutableTypeReference("Ljava/util/ArrayList;")));
            instructions.add(new ImmutableInstruction35c(Opcode.INVOKE_DIRECT, 1, 0, 0, 0, 0, 0,
                    new ImmutableMethodReference("Ljava/util/ArrayList;", "<init>", Collections.emptyList(), "V")));
            instructions.add(new ImmutableInstruction11x(Opcode.RETURN_OBJECT, 0));
        } else {
            // Default to boolean/int values for primitive returns, or null for object returns
            int val = (action == PatchAction.RETURN_TRUE) ? 1 : 0;
            if ("J".equals(retType) || "D".equals(retType)) {
                instructions.add(new ImmutableInstruction21s(Opcode.CONST_WIDE_16, 0, val));
                instructions.add(new ImmutableInstruction11x(Opcode.RETURN_WIDE, 0));
            } else if ("Z".equals(retType) || "B".equals(retType) || "S".equals(retType) || "C".equals(retType) || "I".equals(retType) || "F".equals(retType)) {
                instructions.add(new ImmutableInstruction11n(Opcode.CONST_4, 0, val));
                instructions.add(new ImmutableInstruction11x(Opcode.RETURN, 0));
            } else {
                // Object / Array return type (returning null)
                instructions.add(new ImmutableInstruction11n(Opcode.CONST_4, 0, 0));
                instructions.add(new ImmutableInstruction11x(Opcode.RETURN_OBJECT, 0));
            }
        }

        return new ImmutableMethodImplementation(totalRegisters, instructions, null, null);
    }

    private static void copyStream(InputStream in, OutputStream out) throws IOException {
        byte[] buffer = new byte[65536];
        int read;
        while ((read = in.read(buffer)) != -1) {
            out.write(buffer, 0, read);
        }
    }
}
