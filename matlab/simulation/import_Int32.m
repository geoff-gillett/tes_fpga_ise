function traces = import_Int32( proj,tb,file,rows )
repo='c:\TES_project\fpga_ise\';
filename=sprintf('%s%s\\planAhead\\%s.sim\\%s\\%s',repo,proj,proj,tb,file);
traces=importInt32(filename,rows);
end

