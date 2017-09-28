#include "plugin.h"
#include <utf8.h>

#define _GATANPLUGIN_USE_CLASS_PLUGINMAIN
#include "DMPlugInMain.h"

using namespace Gatan;

DM_StringToken_1Ref h5_version(void)
{
	DM::String str;
	
	PLUG_IN_ENTRY
	
	str = DM::String(HDF5_PLUGIN_VERSION);
	
	PLUG_IN_EXIT

	return str.release();
}

bool h5_is_file(const char* filename)
{
    return H5Fis_hdf5(filename) > 0;
}

void HDF5Plugin::Start()
{
    AddFunction("dm_string h5_version()", &h5_version);
    AddFunction("bool h5_is_file(string filename)", &h5_is_file);

    AddFunction("TagGroup h5_info(string filename)", &h5_info_root);
    AddFunction("TagGroup h5_info(string filename, dm_string location)", &h5_info_location);
    AddFunction("bool h5_delete(string filename, dm_string location)", &h5_delete);
    AddFunction("bool h5_exists(string filename, dm_string location)", &h5_exists);

    AddFunction("TagGroup h5_read_attr(string filename, dm_string location)", &h5_read_attr);
    AddFunction("bool h5_delete_attr(string filename, dm_string location, dm_string attr)", &h5_delete_attr);
    AddFunction("bool h5_exists_attr(string filename, dm_string location, dm_string attr)", &h5_exists_attr);

    AddFunction("bool h5_create_dataset(string filename, dm_string location, Image* data)", &h5_create_dataset_from_image);
    AddFunction("bool h5_create_dataset(string filename, dm_string location, long dtype, TagGroup size)", &h5_create_dataset_simple);
    AddFunction("ImageRef h5_read_dataset(string filename, dm_string location)", &h5_read_dataset_all);
    AddFunction("dm_string h5_read_string_dataset(string filename, dm_string location)", &h5_read_string_dataset);
}

///
/// This is called when the plugin is loaded, after the 'Start' method.
/// Whenever DM is launched, it calls the 'Run' method for
/// each installed plugin after the 'Start' method has been called
/// for all such plugins and all script packages have been installed.
/// Thus it is ok to use script functions provided by other plugins.
///
void HDF5Plugin::Run()
{
}

///
/// This is called when the plugin is unloaded.  Whenever DM is
/// shut down, the 'Cleanup' method is called for all installed plugins
/// before script packages are uninstalled and before the 'End'
/// method is called for any plugin.  Thus, script functions provided
/// by other plugins are still available.  This method should release
/// resources allocated by 'Run'.
///
void HDF5Plugin::Cleanup()
{
}

///
/// This is called when the plugin is unloaded.  Whenever DM is shut
/// down, the 'End' method is called for all installed plugins after
/// all script packages have been unloaded, and other installed plugins
/// may have already been completely unloaded, so the code should not
/// rely on scripts installed from other plugins.  This method should
/// release resources allocated by 'Start', and in particular should
/// uninstall all installed script functions.
///
void HDF5Plugin::End()
{
}

HDF5Plugin gHDF5PlugIn;
