package build.bytes.sfs;

import com.android.tools.smali.dexlib2.DexFileFactory;
import com.android.tools.smali.dexlib2.Opcodes;
import com.android.tools.smali.dexlib2.iface.ClassDef;
import com.android.tools.smali.dexlib2.iface.DexFile;
import com.android.tools.smali.dexlib2.iface.MultiDexContainer;
import com.android.tools.smali.dexlib2.immutable.ImmutableDexFile;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.util.HashSet;
import java.util.Set;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

public class MergeSfsJar {
    public static void main(String[] args) throws Exception {
        File origJar = new File(args[0]);
        File patcherDex = new File(args[1]);
        File outJar = new File(args[2]);

        Opcodes opcodes = Opcodes.getDefault();
        MultiDexContainer<? extends DexFile> origContainer = DexFileFactory.loadDexContainer(origJar, opcodes);
        DexFile origDex = origContainer.getEntry(origContainer.getDexEntryNames().get(0)).getDexFile();

        MultiDexContainer<? extends DexFile> patcherContainer = DexFileFactory.loadDexContainer(patcherDex, opcodes);
        DexFile pDex = patcherContainer.getEntry(patcherContainer.getDexEntryNames().get(0)).getDexFile();

        Set<ClassDef> mergedClasses = new HashSet<>();
        int origKept = 0;
        for (ClassDef cd : origDex.getClasses()) {
            if (!cd.getType().startsWith("Lbuild/bytes/sfs/")) {
                mergedClasses.add(cd);
                origKept++;
            }
        }

        int patcherAdded = 0;
        for (ClassDef cd : pDex.getClasses()) {
            mergedClasses.add(cd);
            patcherAdded++;
        }

        System.out.println("Orig smali classes kept: " + origKept);
        System.out.println("New SfsPatcher classes added: " + patcherAdded);
        System.out.println("Total classes: " + mergedClasses.size());

        ImmutableDexFile mergedDex = new ImmutableDexFile(opcodes, mergedClasses);
        File tempDex = File.createTempFile("sfs_merged_", ".dex");
        DexFileFactory.writeDexFile(tempDex.getAbsolutePath(), mergedDex);

        try (ZipOutputStream zos = new ZipOutputStream(new FileOutputStream(outJar))) {
            ZipEntry entry = new ZipEntry("classes.dex");
            entry.setTime(System.currentTimeMillis());
            zos.putNextEntry(entry);
            try (FileInputStream fis = new FileInputStream(tempDex)) {
                byte[] buf = new byte[65536];
                int r;
                while ((r = fis.read(buf)) != -1) {
                    zos.write(buf, 0, r);
                }
            }
            zos.closeEntry();
        }

        tempDex.delete();
        System.out.println("Created " + outJar.getAbsolutePath() + " (" + outJar.length() + " bytes)");
    }
}
