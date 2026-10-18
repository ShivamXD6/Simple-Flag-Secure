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
import com.android.tools.smali.dexlib2.iface.instruction.FiveRegisterInstruction;
import com.android.tools.smali.dexlib2.iface.instruction.Instruction;
import com.android.tools.smali.dexlib2.iface.instruction.ReferenceInstruction;
import com.android.tools.smali.dexlib2.iface.instruction.RegisterRangeInstruction;
import com.android.tools.smali.dexlib2.iface.reference.MethodReference;
import com.android.tools.smali.dexlib2.immutable.ImmutableClassDef;
import com.android.tools.smali.dexlib2.immutable.ImmutableMethod;
import com.android.tools.smali.dexlib2.immutable.ImmutableMethodParameter;
import com.android.tools.smali.dexlib2.immutable.ImmutableMethodImplementation;
import com.android.tools.smali.dexlib2.immutable.instruction.ImmutableInstruction10x;
import com.android.tools.smali.dexlib2.immutable.instruction.ImmutableInstruction11n;
import com.android.tools.smali.dexlib2.immutable.instruction.ImmutableInstruction11x;
import com.android.tools.smali.dexlib2.immutable.instruction.ImmutableInstruction12x;
import com.android.tools.smali.dexlib2.immutable.instruction.ImmutableInstruction21c;
import com.android.tools.smali.dexlib2.immutable.instruction.ImmutableInstruction21s;
import com.android.tools.smali.dexlib2.immutable.instruction.ImmutableInstruction21t;
import com.android.tools.smali.dexlib2.immutable.instruction.ImmutableInstruction22b;
import com.android.tools.smali.dexlib2.immutable.instruction.ImmutableInstruction22c;
import com.android.tools.smali.dexlib2.immutable.instruction.ImmutableInstruction23x;
import com.android.tools.smali.dexlib2.immutable.instruction.ImmutableInstruction35c;
import com.android.tools.smali.dexlib2.immutable.instruction.ImmutableInstruction3rc;
import com.android.tools.smali.dexlib2.immutable.reference.ImmutableFieldReference;
import com.android.tools.smali.dexlib2.immutable.reference.ImmutableMethodReference;
import com.android.tools.smali.dexlib2.immutable.reference.ImmutableStringReference;
import com.android.tools.smali.dexlib2.immutable.reference.ImmutableTypeReference;
import com.android.tools.smali.dexlib2.rewriter.ClassDefRewriter;
import com.android.tools.smali.dexlib2.rewriter.DexRewriter;
import com.android.tools.smali.dexlib2.rewriter.Rewriter;
import com.android.tools.smali.dexlib2.rewriter.RewriterModule;
import com.android.tools.smali.dexlib2.rewriter.Rewriters;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
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
        RETURN_VOID,
        RETURN_LIST,
        DYNAMIC_PROP_DIRECT,
        DYNAMIC_PROP_INVERT
    }

    private static final Map<String, PatchAction> SERVICES_PRESET = new HashMap<>();

    static {
        SERVICES_PRESET.put("isSecureLocked", PatchAction.DYNAMIC_PROP_INVERT);
        SERVICES_PRESET.put("hasSecureWindowOnScreen", PatchAction.DYNAMIC_PROP_INVERT);
        SERVICES_PRESET.put("notifyScreenshotListeners", PatchAction.RETURN_LIST);
        SERVICES_PRESET.put("registerScreenCaptureObserver", PatchAction.RETURN_VOID);
        SERVICES_PRESET.put("registerScreenRecordingCallback", PatchAction.RETURN_FALSE);
        SERVICES_PRESET.put("containsSecureLayers", PatchAction.RETURN_FALSE);
        SERVICES_PRESET.put("canBeScreenshotTarget", PatchAction.DYNAMIC_PROP_DIRECT);
        SERVICES_PRESET.put("notAllowCaptureDisplay", PatchAction.DYNAMIC_PROP_INVERT);
        SERVICES_PRESET.put("accessScreenContentEnable", PatchAction.RETURN_TRUE);
        SERVICES_PRESET.put("hasSecure", PatchAction.DYNAMIC_PROP_INVERT);
        SERVICES_PRESET.put("shouldBlockScreenCaptureForApp", PatchAction.RETURN_FALSE);
        SERVICES_PRESET.put("isAllowedDisableScreenshot", PatchAction.DYNAMIC_PROP_INVERT);
        SERVICES_PRESET.put("isScreenshotAllowedByPolicy", PatchAction.DYNAMIC_PROP_DIRECT);
    }

    public static void main(String[] args) {
        long startTime = System.currentTimeMillis();
        if (args.length < 2) {
            System.err.println("Usage: SfsPatcher <input.jar> <output.jar>");
            System.exit(1);
        }

        File inputFile = new File(args[0]);
        File outputFile = new File(args[1]);

        System.out.println("⚡ SFS Parallel DEX Patcher (dexlib2)");
        System.out.println("📁 Target: " + inputFile.getName() + " (" + SERVICES_PRESET.size() + " essential rules)");

        try {
            boolean success = patchJarParallel(inputFile, outputFile, SERVICES_PRESET);
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

        File outDir = outputFile.getParentFile();
        if (outDir == null) outDir = new File(".");
        outDir.mkdirs();
        final File tempDir = outDir;

        entryNames.parallelStream().forEach(entryName -> {
            try {
                DexFile origDex = container.getEntry(entryName).getDexFile();

                Set<String> recordClasses = new HashSet<>();
                Set<String> targetClasses = new HashSet<>();
                for (ClassDef classDef : origDex.getClasses()) {
                    String classType = classDef.getType();
                    if (!classType.startsWith("Lcom/android/server/") &&
                        !classType.startsWith("Landroid/") &&
                        !classType.startsWith("Lcom/miui/") &&
                        !classType.startsWith("Lcom/oplus/") &&
                        !classType.startsWith("Lcom/samsung/")) {
                        continue;
                    }
                    if ("Ljava/lang/Record;".equals(classDef.getSuperclass())) {
                        recordClasses.add(classType);
                    }
                    for (Method method : classDef.getMethods()) {
                        if (patchRules.containsKey(method.getName())) {
                            targetClasses.add(classType);
                            break;
                        }
                        MethodImplementation impl = method.getImplementation();
                        if (impl != null) {
                            for (Instruction inst : impl.getInstructions()) {
                                if (inst instanceof ReferenceInstruction) {
                                    Object ref = ((ReferenceInstruction) inst).getReference();
                                    if (ref instanceof MethodReference) {
                                        MethodReference mr = (MethodReference) ref;
                                        if ("notAllowCaptureDisplay".equals(mr.getName())) {
                                            targetClasses.add(classType);
                                            break;
                                        }
                                        if ("copyFrom".equals(mr.getName()) &&
                                            "Landroid/view/WindowManager$LayoutParams;".equals(mr.getDefiningClass())) {
                                            targetClasses.add(classType);
                                            break;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                if (targetClasses.isEmpty()) {
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
                                if (!targetClasses.contains(type) && !recordClasses.contains(type)) {
                                    return classDef;
                                }

                                boolean needsCaptureHelper = false;
                                MethodReference captureTargetRef = null;
                                Opcode origCaptureInvokeOp = Opcode.INVOKE_INTERFACE;

                                boolean needsCopyFromHelper = false;

                                List<Method> rewrittenMethods = new ArrayList<>();
                                for (Method method : classDef.getMethods()) {
                                    String name = method.getName();
                                    String definingClass = method.getDefiningClass();

                                    if (recordClasses.contains(definingClass) &&
                                        ("equals".equals(name) || "hashCode".equals(name) || "toString".equals(name))) {
                                        MethodImplementation fixedImpl = buildRecordImplementation(method);
                                        String log = entryName + " -> " + definingClass + "->" + name + "() [FIX_RECORD_VERIFY]";
                                        synchronized (System.out) {
                                            System.out.println("   ✓ " + log);
                                        }
                                        patchedDetails.add(log);
                                        rewrittenMethods.add(new ImmutableMethod(
                                                definingClass,
                                                name,
                                                method.getParameters(),
                                                method.getReturnType(),
                                                method.getAccessFlags(),
                                                method.getAnnotations(),
                                                method.getHiddenApiRestrictions(),
                                                fixedImpl
                                        ));
                                        continue;
                                    }

                                    PatchAction action = patchRules.get(name);
                                    if (action != null) {
                                        int flags = method.getAccessFlags();
                                        if ((flags & AccessFlags.ABSTRACT.getValue()) != 0 ||
                                            (flags & AccessFlags.NATIVE.getValue()) != 0) {
                                            rewrittenMethods.add(method);
                                            continue;
                                        }

                                        if (action == PatchAction.RETURN_LIST) {
                                            String origName = name + "$sfs_orig";
                                            boolean isStatic = (flags & AccessFlags.STATIC.getValue()) != 0;
                                            int origFlags = isStatic ? flags : ((flags & ~AccessFlags.PUBLIC.getValue() & ~AccessFlags.PROTECTED.getValue()) | AccessFlags.PRIVATE.getValue());

                                            ImmutableMethod origMethod = new ImmutableMethod(
                                                    definingClass,
                                                    origName,
                                                    method.getParameters(),
                                                    method.getReturnType(),
                                                    origFlags,
                                                    method.getAnnotations(),
                                                    method.getHiddenApiRestrictions(),
                                                    method.getImplementation()
                                            );
                                            rewrittenMethods.add(origMethod);

                                            MethodImplementation wrapperImpl = buildNotifyScreenshotImplementation(method, origName);
                                            ImmutableMethod wrapperMethod = new ImmutableMethod(
                                                    definingClass,
                                                    name,
                                                    method.getParameters(),
                                                    method.getReturnType(),
                                                    method.getAccessFlags(),
                                                    method.getAnnotations(),
                                                    method.getHiddenApiRestrictions(),
                                                    wrapperImpl
                                            );
                                            rewrittenMethods.add(wrapperMethod);
                                        } else {
                                            MethodImplementation newImpl = buildImplementation(method, action);
                                            rewrittenMethods.add(new ImmutableMethod(
                                                    definingClass,
                                                    name,
                                                    method.getParameters(),
                                                    method.getReturnType(),
                                                    method.getAccessFlags(),
                                                    method.getAnnotations(),
                                                    method.getHiddenApiRestrictions(),
                                                    newImpl
                                            ));
                                        }

                                        String log = entryName + " -> " + definingClass + "->" + name + "() [" + action + "]";
                                        synchronized (System.out) {
                                            System.out.println("   ✓ " + log);
                                        }
                                        patchedDetails.add(log);
                                        continue;
                                    }

                                    MethodImplementation impl = method.getImplementation();
                                    if (impl != null) {
                                        boolean methodChanged = false;
                                        List<Instruction> newInstructions = new ArrayList<>();
                                        for (Instruction inst : impl.getInstructions()) {
                                            if (inst instanceof ReferenceInstruction) {
                                                Object ref = ((ReferenceInstruction) inst).getReference();
                                                if (ref instanceof MethodReference) {
                                                    MethodReference mr = (MethodReference) ref;
                                                    if ("notAllowCaptureDisplay".equals(mr.getName())) {
                                                        captureTargetRef = mr;
                                                        origCaptureInvokeOp = inst.getOpcode();
                                                        List<String> helperParams = new ArrayList<>();
                                                        helperParams.add(mr.getDefiningClass());
                                                        for (CharSequence p : mr.getParameterTypes()) {
                                                            helperParams.add(p.toString());
                                                        }
                                                        ImmutableMethodReference sfsRef = new ImmutableMethodReference(
                                                                definingClass,
                                                                "sfs$notAllowCaptureDisplay",
                                                                helperParams,
                                                                mr.getReturnType()
                                                        );
                                                        if (inst instanceof FiveRegisterInstruction) {
                                                            FiveRegisterInstruction fri = (FiveRegisterInstruction) inst;
                                                            newInstructions.add(new ImmutableInstruction35c(
                                                                    Opcode.INVOKE_STATIC,
                                                                    fri.getRegisterCount(),
                                                                    fri.getRegisterC(),
                                                                    fri.getRegisterD(),
                                                                    fri.getRegisterE(),
                                                                    fri.getRegisterF(),
                                                                    fri.getRegisterG(),
                                                                    sfsRef
                                                            ));
                                                            methodChanged = true;
                                                            needsCaptureHelper = true;
                                                            continue;
                                                        } else if (inst instanceof RegisterRangeInstruction) {
                                                            RegisterRangeInstruction rri = (RegisterRangeInstruction) inst;
                                                            newInstructions.add(new ImmutableInstruction3rc(
                                                                    Opcode.INVOKE_STATIC_RANGE,
                                                                    rri.getStartRegister(),
                                                                    rri.getRegisterCount(),
                                                                    sfsRef
                                                            ));
                                                            methodChanged = true;
                                                            needsCaptureHelper = true;
                                                            continue;
                                                        }
                                                    } else if ("copyFrom".equals(mr.getName()) &&
                                                               "Landroid/view/WindowManager$LayoutParams;".equals(mr.getDefiningClass())) {
                                                        ImmutableMethodReference sfsCopyRef = new ImmutableMethodReference(
                                                                definingClass,
                                                                "sfs$copyFrom",
                                                                Arrays.asList("Landroid/view/WindowManager$LayoutParams;", "Landroid/view/WindowManager$LayoutParams;"),
                                                                "I"
                                                        );
                                                        if (inst instanceof FiveRegisterInstruction) {
                                                            FiveRegisterInstruction fri = (FiveRegisterInstruction) inst;
                                                            newInstructions.add(new ImmutableInstruction35c(
                                                                    Opcode.INVOKE_STATIC,
                                                                    fri.getRegisterCount(),
                                                                    fri.getRegisterC(),
                                                                    fri.getRegisterD(),
                                                                    fri.getRegisterE(),
                                                                    fri.getRegisterF(),
                                                                    fri.getRegisterG(),
                                                                    sfsCopyRef
                                                            ));
                                                            methodChanged = true;
                                                            needsCopyFromHelper = true;
                                                            continue;
                                                        } else if (inst instanceof RegisterRangeInstruction) {
                                                            RegisterRangeInstruction rri = (RegisterRangeInstruction) inst;
                                                            newInstructions.add(new ImmutableInstruction3rc(
                                                                    Opcode.INVOKE_STATIC_RANGE,
                                                                    rri.getStartRegister(),
                                                                    rri.getRegisterCount(),
                                                                    sfsCopyRef
                                                            ));
                                                            methodChanged = true;
                                                            needsCopyFromHelper = true;
                                                            continue;
                                                        }
                                                    }
                                                }
                                            }
                                            newInstructions.add(inst);
                                        }

                                        if (methodChanged) {
                                            MethodImplementation newImpl = new ImmutableMethodImplementation(
                                                    impl.getRegisterCount(),
                                                    newInstructions,
                                                    impl.getTryBlocks(),
                                                    impl.getDebugItems()
                                            );
                                            rewrittenMethods.add(new ImmutableMethod(
                                                    definingClass,
                                                    name,
                                                    method.getParameters(),
                                                    method.getReturnType(),
                                                    method.getAccessFlags(),
                                                    method.getAnnotations(),
                                                    method.getHiddenApiRestrictions(),
                                                    newImpl
                                            ));
                                            String log = entryName + " -> " + definingClass + "->" + name + "() [INTERCEPT_CALLS]";
                                            synchronized (System.out) {
                                                System.out.println("   ✓ " + log);
                                            }
                                            patchedDetails.add(log);
                                            continue;
                                        }
                                    }

                                    rewrittenMethods.add(method);
                                }

                                if (needsCaptureHelper && captureTargetRef != null) {
                                    Method helper = createSfsNotAllowCaptureDisplayMethod(type, captureTargetRef, origCaptureInvokeOp);
                                    rewrittenMethods.add(helper);
                                    String log = entryName + " -> " + type + "->sfs$notAllowCaptureDisplay() [HELPER_ADDED]";
                                    synchronized (System.out) {
                                        System.out.println("   ✓ " + log);
                                    }
                                    patchedDetails.add(log);
                                }

                                if (needsCopyFromHelper) {
                                    Method helper = createSfsCopyFromMethod(type);
                                    rewrittenMethods.add(helper);
                                    String log = entryName + " -> " + type + "->sfs$copyFrom() [HELPER_ADDED]";
                                    synchronized (System.out) {
                                        System.out.println("   ✓ " + log);
                                    }
                                    patchedDetails.add(log);
                                }

                                return new ImmutableClassDef(
                                        classDef.getType(),
                                        classDef.getAccessFlags(),
                                        classDef.getSuperclass(),
                                        classDef.getInterfaces(),
                                        classDef.getSourceFile(),
                                        classDef.getAnnotations(),
                                        classDef.getFields(),
                                        rewrittenMethods
                                );
                            }
                        };
                    }
                });

                DexFile rewrittenDex = rewriter.getDexFileRewriter().rewrite(origDex);

                String safePrefix = "sfs_" + entryName.replaceAll("[^a-zA-Z0-9]", "_") + "_";
                File tempDex = File.createTempFile(safePrefix, ".dex", tempDir);
                tempDex.deleteOnExit();
                DexFileFactory.writeDexFile(tempDex.getAbsolutePath(), rewrittenDex);
                modifiedDexFiles.put(entryName, tempDex);
                totalPatchedMethods.addAndGet(patchedDetails.size());
            } catch (Exception e) {
                throw new RuntimeException("Error processing " + entryName, e);
            }
        });

        if (totalPatchedMethods.get() == 0) {
            System.out.println("⚠️ Warning: No target methods matched in any DEX file!");
            for (File f : modifiedDexFiles.values()) {
                if (f.exists()) f.delete();
            }
            return false;
        }

        long patchDuration = System.currentTimeMillis() - phaseStart;
        System.out.println("⏱️ Bytecode patched in " + (patchDuration / 1000.0) + "s");

        long repackStart = System.currentTimeMillis();
        System.out.println("🖇️ Repacking archive (updating " + modifiedDexFiles.size() + " DEX file(s))...");
        if (outputFile.getParentFile() != null) {
            outputFile.getParentFile().mkdirs();
        }

        // Group modified DEX files by base zip entry name (e.g. "classes.dex/1" -> "classes.dex")
        Map<String, Map<Integer, File>> containerMods = new HashMap<>();
        Map<String, File> standaloneMods = new HashMap<>();

        for (Map.Entry<String, File> mod : modifiedDexFiles.entrySet()) {
            String key = mod.getKey();
            int slashIdx = key.indexOf('/');
            if (slashIdx != -1) {
                String baseZipName = key.substring(0, slashIdx);
                int subIndex = Integer.parseInt(key.substring(slashIdx + 1));
                containerMods.computeIfAbsent(baseZipName, k -> new HashMap<>()).put(subIndex, mod.getValue());
            } else {
                standaloneMods.put(key, mod.getValue());
            }
        }

        Set<String> writtenEntries = new HashSet<>();

        try (ZipFile zipIn = new ZipFile(inputFile);
             ZipOutputStream zos = new ZipOutputStream(new BufferedOutputStream(new FileOutputStream(outputFile), 65536))) {

            zos.setLevel(Deflater.BEST_SPEED);
            Enumeration<? extends ZipEntry> entries = zipIn.entries();
            while (entries.hasMoreElements()) {
                ZipEntry entry = entries.nextElement();
                String name = entry.getName();

                if (containerMods.containsKey(name)) {
                    // Container (e.g. classes.dex with subdexes): unbundle to standard Multi-DEX
                    Map<Integer, File> modMap = containerMods.get(name);
                    List<String> subEntryNames = new ArrayList<>();
                    for (String en : entryNames) {
                        if (en.startsWith(name + "/")) {
                            subEntryNames.add(en);
                        }
                    }
                    subEntryNames.sort((a, b) -> {
                        int idxA = Integer.parseInt(a.substring(name.length() + 1));
                        int idxB = Integer.parseInt(b.substring(name.length() + 1));
                        return Integer.compare(idxA, idxB);
                    });

                    for (String subName : subEntryNames) {
                        int subIndex = Integer.parseInt(subName.substring(name.length() + 1));
                        String targetDexName = (subIndex == 0) ? name : name.replace(".dex", (subIndex + 1) + ".dex");

                        File dexToStore;
                        boolean deleteAfter = false;
                        if (modMap.containsKey(subIndex)) {
                            dexToStore = modMap.get(subIndex);
                            deleteAfter = true;
                        } else {
                            dexToStore = File.createTempFile("sfs_sub_" + subIndex + "_", ".dex", tempDir);
                            deleteAfter = true;
                            DexFile subDex = container.getEntry(subName).getDexFile();
                            DexFileFactory.writeDexFile(dexToStore.getAbsolutePath(), subDex);
                        }

                        writeStoredEntry(zos, targetDexName, dexToStore);
                        writtenEntries.add(targetDexName);
                        if (deleteAfter) {
                            dexToStore.delete();
                        }
                    }
                } else if (standaloneMods.containsKey(name)) {
                    File patchedDex = standaloneMods.get(name);
                    writeStoredEntry(zos, name, patchedDex);
                    writtenEntries.add(name);
                    patchedDex.delete();
                } else {
                    if (writtenEntries.contains(name)) {
                        continue;
                    }
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
                    writtenEntries.add(name);
                }
            }
        } finally {
            for (File f : modifiedDexFiles.values()) {
                if (f.exists()) f.delete();
            }
        }

        long repackDuration = System.currentTimeMillis() - repackStart;
        System.out.println("⏱️ Repack completed in " + (repackDuration / 1000.0) + "s");

        return true;
    }

    private static void writeStoredEntry(ZipOutputStream zos, String name, File file) throws IOException {
        ZipEntry entry = new ZipEntry(name);
        entry.setMethod(ZipEntry.STORED);
        entry.setSize(file.length());
        entry.setCompressedSize(file.length());
        entry.setTime(System.currentTimeMillis());

        java.util.zip.CRC32 crc = new java.util.zip.CRC32();
        try (InputStream fis = new BufferedInputStream(new FileInputStream(file), 65536)) {
            byte[] buf = new byte[65536];
            int n;
            while ((n = fis.read(buf)) != -1) {
                crc.update(buf, 0, n);
            }
        }
        entry.setCrc(crc.getValue());
        zos.putNextEntry(entry);
        try (InputStream fis = new BufferedInputStream(new FileInputStream(file), 65536)) {
            copyStream(fis, zos);
        }
        zos.closeEntry();
    }

    private static int countParamRegisters(Method method) {
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
        return paramRegs;
    }

    private static MethodImplementation buildRecordImplementation(Method method) {
        String name = method.getName();
        int paramRegs = countParamRegisters(method);
        int totalRegisters = Math.max(1, paramRegs + 1);

        List<Instruction> instructions = new ArrayList<>();
        if ("toString".equals(name)) {
            instructions.add(new ImmutableInstruction21c(Opcode.CONST_STRING, 0, new ImmutableStringReference("")));
            instructions.add(new ImmutableInstruction11x(Opcode.RETURN_OBJECT, 0));
        } else if ("equals".equals(name) || "hashCode".equals(name)) {
            instructions.add(new ImmutableInstruction11n(Opcode.CONST_4, 0, 0));
            instructions.add(new ImmutableInstruction11x(Opcode.RETURN, 0));
        } else {
            return buildImplementation(method, PatchAction.RETURN_FALSE);
        }

        return new ImmutableMethodImplementation(totalRegisters, instructions, null, null);
    }

    private static MethodImplementation buildImplementation(Method method, PatchAction action) {
        if (action == PatchAction.DYNAMIC_PROP_DIRECT || action == PatchAction.DYNAMIC_PROP_INVERT) {
            return buildDynamicBooleanImplementation(method, action == PatchAction.DYNAMIC_PROP_INVERT);
        }

        int paramRegs = countParamRegisters(method);
        int totalRegisters = Math.max(1, paramRegs + 1);

        List<Instruction> instructions = new ArrayList<>();
        String retType = method.getReturnType();

        if (action == PatchAction.RETURN_LIST && (retType.startsWith("L") || retType.startsWith("["))) {
            instructions.add(new ImmutableInstruction21c(Opcode.NEW_INSTANCE, 0, new ImmutableTypeReference("Ljava/util/ArrayList;")));
            instructions.add(new ImmutableInstruction35c(Opcode.INVOKE_DIRECT, 1, 0, 0, 0, 0, 0,
                    new ImmutableMethodReference("Ljava/util/ArrayList;", "<init>", Collections.emptyList(), "V")));
            instructions.add(new ImmutableInstruction11x(Opcode.RETURN_OBJECT, 0));
        } else if (action == PatchAction.RETURN_VOID || "V".equals(retType)) {
            instructions.add(new ImmutableInstruction10x(Opcode.RETURN_VOID));
        } else {
            int val = (action == PatchAction.RETURN_TRUE) ? 1 : 0;
            if ("J".equals(retType) || "D".equals(retType)) {
                instructions.add(new ImmutableInstruction21s(Opcode.CONST_WIDE_16, 0, val));
                instructions.add(new ImmutableInstruction11x(Opcode.RETURN_WIDE, 0));
            } else if ("Z".equals(retType) || "B".equals(retType) || "S".equals(retType) || "C".equals(retType) || "I".equals(retType) || "F".equals(retType)) {
                instructions.add(new ImmutableInstruction11n(Opcode.CONST_4, 0, val));
                instructions.add(new ImmutableInstruction11x(Opcode.RETURN, 0));
            } else {
                instructions.add(new ImmutableInstruction11n(Opcode.CONST_4, 0, 0));
                instructions.add(new ImmutableInstruction11x(Opcode.RETURN_OBJECT, 0));
            }
        }

        return new ImmutableMethodImplementation(totalRegisters, instructions, null, null);
    }

    private static MethodImplementation buildDynamicBooleanImplementation(Method method, boolean invert) {
        int paramRegs = countParamRegisters(method);
        int totalRegisters = Math.max(2, paramRegs + 2);

        List<Instruction> instructions = new ArrayList<>();
        instructions.add(new ImmutableInstruction21c(Opcode.CONST_STRING, 0, new ImmutableStringReference("persist.sys.sfs.screenshot")));
        instructions.add(new ImmutableInstruction11n(Opcode.CONST_4, 1, 1));
        instructions.add(new ImmutableInstruction35c(Opcode.INVOKE_STATIC, 2, 0, 1, 0, 0, 0,
                new ImmutableMethodReference("Landroid/os/SystemProperties;", "getBoolean", Arrays.asList("Ljava/lang/String;", "Z"), "Z")));
        instructions.add(new ImmutableInstruction11x(Opcode.MOVE_RESULT, 0));

        if (invert) {
            instructions.add(new ImmutableInstruction22b(Opcode.XOR_INT_LIT8, 0, 0, 1));
        }

        instructions.add(new ImmutableInstruction11x(Opcode.RETURN, 0));

        return new ImmutableMethodImplementation(totalRegisters, instructions, null, null);
    }

    interface InstItem {
        int getCodeUnits();
    }

    static class RealInst implements InstItem {
        final Instruction inst;
        RealInst(Instruction inst) { this.inst = inst; }
        public int getCodeUnits() { return inst.getCodeUnits(); }
    }

    static class LabelItem implements InstItem {
        final String name;
        LabelItem(String name) { this.name = name; }
        public int getCodeUnits() { return 0; }
    }

    static class Branch21t implements InstItem {
        final Opcode opcode;
        final int reg;
        final String targetLabel;
        Branch21t(Opcode opcode, int reg, String targetLabel) {
            this.opcode = opcode;
            this.reg = reg;
            this.targetLabel = targetLabel;
        }
        public int getCodeUnits() { return 2; }
    }

    private static List<Instruction> resolveInstructions(List<InstItem> items) {
        Map<String, Integer> labelOffsets = new HashMap<>();
        int currentUnit = 0;
        for (InstItem item : items) {
            if (item instanceof LabelItem) {
                labelOffsets.put(((LabelItem) item).name, currentUnit);
            } else {
                currentUnit += item.getCodeUnits();
            }
        }
        List<Instruction> result = new ArrayList<>();
        currentUnit = 0;
        for (InstItem item : items) {
            if (item instanceof RealInst) {
                result.add(((RealInst) item).inst);
                currentUnit += item.getCodeUnits();
            } else if (item instanceof Branch21t) {
                Branch21t b = (Branch21t) item;
                int offset = labelOffsets.get(b.targetLabel) - currentUnit;
                result.add(new ImmutableInstruction21t(b.opcode, b.reg, offset));
                currentUnit += b.getCodeUnits();
            }
        }
        return result;
    }

    private static MethodImplementation buildNotifyScreenshotImplementation(Method method, String origMethodName) {
        boolean isStatic = (method.getAccessFlags() & AccessFlags.STATIC.getValue()) != 0;
        int paramRegs = countParamRegisters(method);
        int localRegs = 2; // v0, v1
        int totalRegisters = Math.max(2, paramRegs + localRegs);
        int p0 = totalRegisters - paramRegs;

        List<InstItem> items = new ArrayList<>();
        items.add(new RealInst(new ImmutableInstruction21c(Opcode.CONST_STRING, 0, new ImmutableStringReference("persist.sys.sfs.screenshot"))));
        items.add(new RealInst(new ImmutableInstruction11n(Opcode.CONST_4, 1, 1)));
        items.add(new RealInst(new ImmutableInstruction35c(Opcode.INVOKE_STATIC, 2, 0, 1, 0, 0, 0,
                new ImmutableMethodReference("Landroid/os/SystemProperties;", "getBoolean", Arrays.asList("Ljava/lang/String;", "Z"), "Z"))));
        items.add(new RealInst(new ImmutableInstruction11x(Opcode.MOVE_RESULT, 0)));

        items.add(new Branch21t(Opcode.IF_EQZ, 0, "delegate_orig"));

        items.add(new RealInst(new ImmutableInstruction21c(Opcode.NEW_INSTANCE, 0, new ImmutableTypeReference("Ljava/util/ArrayList;"))));
        items.add(new RealInst(new ImmutableInstruction35c(Opcode.INVOKE_DIRECT, 1, 0, 0, 0, 0, 0,
                new ImmutableMethodReference("Ljava/util/ArrayList;", "<init>", Collections.emptyList(), "V"))));
        items.add(new RealInst(new ImmutableInstruction11x(Opcode.RETURN_OBJECT, 0)));

        items.add(new LabelItem("delegate_orig"));
        Opcode invOp = isStatic ? Opcode.INVOKE_STATIC : Opcode.INVOKE_DIRECT;
        int r0 = (paramRegs > 0) ? p0 : 0;
        int r1 = (paramRegs > 1) ? p0 + 1 : 0;
        int r2 = (paramRegs > 2) ? p0 + 2 : 0;
        int r3 = (paramRegs > 3) ? p0 + 3 : 0;
        int r4 = (paramRegs > 4) ? p0 + 4 : 0;
        List<String> paramTypes = new ArrayList<>();
        for (MethodParameter p : method.getParameters()) {
            paramTypes.add(p.getType());
        }
        ImmutableMethodReference ref = new ImmutableMethodReference(method.getDefiningClass(), origMethodName, paramTypes, method.getReturnType());

        if (paramRegs <= 5) {
            items.add(new RealInst(new ImmutableInstruction35c(invOp, paramRegs, r0, r1, r2, r3, r4, ref)));
        } else {
            Opcode rangeOp = isStatic ? Opcode.INVOKE_STATIC_RANGE : Opcode.INVOKE_DIRECT_RANGE;
            items.add(new RealInst(new ImmutableInstruction3rc(rangeOp, p0, paramRegs, ref)));
        }

        items.add(new RealInst(new ImmutableInstruction11x(Opcode.MOVE_RESULT_OBJECT, 0)));
        items.add(new RealInst(new ImmutableInstruction11x(Opcode.RETURN_OBJECT, 0)));

        return new ImmutableMethodImplementation(totalRegisters, resolveInstructions(items), null, null);
    }

    private static Method createSfsNotAllowCaptureDisplayMethod(String definingClass, MethodReference targetRef, Opcode origInvokeOp) {
        int paramRegs = 1; // for receiver stub
        for (CharSequence cs : targetRef.getParameterTypes()) {
            String pType = cs.toString();
            if ("J".equals(pType) || "D".equals(pType)) {
                paramRegs += 2;
            } else {
                paramRegs += 1;
            }
        }
        int localRegs = 2; // v0, v1
        int totalRegisters = Math.max(2, paramRegs + localRegs);
        int p0 = totalRegisters - paramRegs;

        List<InstItem> items = new ArrayList<>();
        items.add(new RealInst(new ImmutableInstruction21c(Opcode.CONST_STRING, 0, new ImmutableStringReference("persist.sys.sfs.screenshot"))));
        items.add(new RealInst(new ImmutableInstruction11n(Opcode.CONST_4, 1, 1)));
        items.add(new RealInst(new ImmutableInstruction35c(Opcode.INVOKE_STATIC, 2, 0, 1, 0, 0, 0,
                new ImmutableMethodReference("Landroid/os/SystemProperties;", "getBoolean", Arrays.asList("Ljava/lang/String;", "Z"), "Z"))));
        items.add(new RealInst(new ImmutableInstruction11x(Opcode.MOVE_RESULT, 0)));

        items.add(new Branch21t(Opcode.IF_EQZ, 0, "sfs_disabled"));
        items.add(new RealInst(new ImmutableInstruction11n(Opcode.CONST_4, 0, 0)));
        items.add(new RealInst(new ImmutableInstruction11x(Opcode.RETURN, 0)));

        items.add(new LabelItem("sfs_disabled"));
        items.add(new Branch21t(Opcode.IF_EQZ, p0, "stub_null"));

        Opcode delegateOp = (origInvokeOp == Opcode.INVOKE_INTERFACE || origInvokeOp == Opcode.INVOKE_INTERFACE_RANGE)
                ? Opcode.INVOKE_INTERFACE : Opcode.INVOKE_VIRTUAL;
        int r0 = (paramRegs > 0) ? p0 : 0;
        int r1 = (paramRegs > 1) ? p0 + 1 : 0;
        int r2 = (paramRegs > 2) ? p0 + 2 : 0;
        int r3 = (paramRegs > 3) ? p0 + 3 : 0;
        int r4 = (paramRegs > 4) ? p0 + 4 : 0;
        if (paramRegs <= 5) {
            items.add(new RealInst(new ImmutableInstruction35c(delegateOp, paramRegs, r0, r1, r2, r3, r4, targetRef)));
        } else {
            Opcode rangeOp = (delegateOp == Opcode.INVOKE_INTERFACE) ? Opcode.INVOKE_INTERFACE_RANGE : Opcode.INVOKE_VIRTUAL_RANGE;
            items.add(new RealInst(new ImmutableInstruction3rc(rangeOp, p0, paramRegs, targetRef)));
        }
        items.add(new RealInst(new ImmutableInstruction11x(Opcode.MOVE_RESULT, 0)));
        items.add(new RealInst(new ImmutableInstruction11x(Opcode.RETURN, 0)));

        items.add(new LabelItem("stub_null"));
        items.add(new RealInst(new ImmutableInstruction11n(Opcode.CONST_4, 0, 0)));
        items.add(new RealInst(new ImmutableInstruction11x(Opcode.RETURN, 0)));

        MethodImplementation impl = new ImmutableMethodImplementation(totalRegisters, resolveInstructions(items), null, null);

        List<MethodParameter> params = new ArrayList<>();
        params.add(new ImmutableMethodParameter(targetRef.getDefiningClass(), Collections.emptySet(), "stub"));
        int pIdx = 1;
        for (CharSequence cs : targetRef.getParameterTypes()) {
            params.add(new ImmutableMethodParameter(cs.toString(), Collections.emptySet(), "param" + (pIdx++)));
        }

        return new ImmutableMethod(
                definingClass,
                "sfs$notAllowCaptureDisplay",
                params,
                "Z",
                AccessFlags.PRIVATE.getValue() | AccessFlags.STATIC.getValue(),
                Collections.emptySet(),
                Collections.emptySet(),
                impl
        );
    }

    private static Method createSfsCopyFromMethod(String definingClass) {
        int totalRegisters = 5;
        int v0 = 0;
        int v1 = 1;
        int v2 = 2;
        int p0 = 3;
        int p1 = 4;

        List<InstItem> items = new ArrayList<>();

        items.add(new Branch21t(Opcode.IF_NEZ, p0, "target_valid"));
        items.add(new RealInst(new ImmutableInstruction11n(Opcode.CONST_4, v0, 0)));
        items.add(new RealInst(new ImmutableInstruction11x(Opcode.RETURN, v0)));

        items.add(new LabelItem("target_valid"));
        items.add(new RealInst(new ImmutableInstruction35c(
                Opcode.INVOKE_VIRTUAL,
                2,
                p0, p1, 0, 0, 0,
                new ImmutableMethodReference(
                        "Landroid/view/WindowManager$LayoutParams;",
                        "copyFrom",
                        Collections.singletonList("Landroid/view/WindowManager$LayoutParams;"),
                        "I"
                )
        )));
        items.add(new RealInst(new ImmutableInstruction11x(Opcode.MOVE_RESULT, v0)));

        items.add(new RealInst(new ImmutableInstruction21c(Opcode.CONST_STRING, v1, new ImmutableStringReference("persist.sys.sfs.screenshot"))));
        items.add(new RealInst(new ImmutableInstruction11n(Opcode.CONST_4, v2, 1)));
        items.add(new RealInst(new ImmutableInstruction35c(
                Opcode.INVOKE_STATIC,
                2,
                v1, v2, 0, 0, 0,
                new ImmutableMethodReference(
                        "Landroid/os/SystemProperties;",
                        "getBoolean",
                        Arrays.asList("Ljava/lang/String;", "Z"),
                        "Z"
                )
        )));
        items.add(new RealInst(new ImmutableInstruction11x(Opcode.MOVE_RESULT, v1)));
        items.add(new Branch21t(Opcode.IF_EQZ, v1, "done"));

        items.add(new RealInst(new ImmutableInstruction21s(Opcode.CONST_16, v2, 0x2000)));
        items.add(new RealInst(new ImmutableInstruction12x(Opcode.NOT_INT, v2, v2)));

        ImmutableFieldReference flagsField = new ImmutableFieldReference(
                "Landroid/view/WindowManager$LayoutParams;",
                "flags",
                "I"
        );
        items.add(new RealInst(new ImmutableInstruction22c(Opcode.IGET, v1, p0, flagsField)));
        items.add(new RealInst(new ImmutableInstruction23x(Opcode.AND_INT, v1, v1, v2)));
        items.add(new RealInst(new ImmutableInstruction22c(Opcode.IPUT, v1, p0, flagsField)));

        items.add(new Branch21t(Opcode.IF_EQZ, p1, "done"));
        items.add(new RealInst(new ImmutableInstruction22c(Opcode.IGET, v1, p1, flagsField)));
        items.add(new RealInst(new ImmutableInstruction23x(Opcode.AND_INT, v1, v1, v2)));
        items.add(new RealInst(new ImmutableInstruction22c(Opcode.IPUT, v1, p1, flagsField)));

        items.add(new LabelItem("done"));
        items.add(new RealInst(new ImmutableInstruction11x(Opcode.RETURN, v0)));

        MethodImplementation impl = new ImmutableMethodImplementation(totalRegisters, resolveInstructions(items), null, null);

        List<MethodParameter> params = Arrays.asList(
                new ImmutableMethodParameter("Landroid/view/WindowManager$LayoutParams;", Collections.emptySet(), "target"),
                new ImmutableMethodParameter("Landroid/view/WindowManager$LayoutParams;", Collections.emptySet(), "source")
        );

        return new ImmutableMethod(
                definingClass,
                "sfs$copyFrom",
                params,
                "I",
                AccessFlags.PRIVATE.getValue() | AccessFlags.STATIC.getValue(),
                Collections.emptySet(),
                Collections.emptySet(),
                impl
        );
    }

    private static void copyStream(InputStream in, OutputStream out) throws IOException {
        byte[] buffer = new byte[65536];
        int read;
        while ((read = in.read(buffer)) != -1) {
            out.write(buffer, 0, read);
        }
    }
}
