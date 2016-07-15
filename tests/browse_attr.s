string cur_dir = GetApplicationDirectory(0, 0);
string file_path = PathConcatenate(cur_dir, "attr.hdf5");
TagGroup tags = h5_read_attr(file_path, "data");
tags.TagGroupOpenBrowserWindow( 0 );
