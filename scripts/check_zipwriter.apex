Compression.ZipWriter zipWriter = new Compression.ZipWriter();
zipWriter.addEntry('test.txt', Blob.valueOf('ok'));
Blob outBlob = zipWriter.getArchive();
System.debug(outBlob.size());
