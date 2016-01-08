function data = importsimdata(filename,rows)

fd = fopen(filename,'r');
data=fread(fd,[rows,inf],'int32',0,'l');
fclose(fd);

