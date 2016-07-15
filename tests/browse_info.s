string cur_dir = GetApplicationDirectory(0, 0);
string file_path = PathConcatenate(cur_dir, "test2.hdf5");
TagGroup info = h5_info(file_path, "/");
info.TagGroupOpenBrowserWindow( 0 );
