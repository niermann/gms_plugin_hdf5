#ifndef HDF5_AUTOHANDLE_INC
#define HDF5_AUTOHANDLE_INC

#include <hdf5.h>
#include <algorithm>

// Forwards
void debug(const char* fmt, ...);

typedef herr_t (*auto_handle_closer_t)(hid_t);

/**
 * A wrapper class for HDF5 handles (hid_t), that provides RAII semantics.
 * The class interface is designed like auto_ptr.
 * No method throws an exception.
 */
template <auto_handle_closer_t closer> class auto_handle
{
private:
    hid_t hid;

public:
    /** Default CTOR: Creates invalid handle. */
    auto_handle() throw (): hid(-1) {}

    /** Copy CTOR: Transfers handle ownership to the newly created handle. */
    auto_handle(auto_handle<closer>& h) throw () : hid(h.hid) { h.hid = -1; }

    /** Create handle from hid_t. */
    explicit auto_handle(hid_t id) throw () : hid(id) 
    {
//      if (valid())
//          debug("CREATE %s hid=%x\n", typeid(*this).name(), hid);
    }

    // DTOR
    ~auto_handle() throw () 
    { 
        if (valid()) {
//          debug("DESTROY %s hid=%x\n", typeid(*this).name(), hid);
            closer(hid); 
        }
    }

    /** Assign handle. Ownership is transferred to this class. */
    auto_handle& operator=(auto_handle<closer>& h) throw ()
    {
        reset(h.release());
        return *this;
    }

    /** Returns true, if this is a valid handle */
    bool valid() const throw () { return hid >= 0; }

    /** Swaps to handles. */
    void swap(auto_handle<closer>& h) throw () { std::swap(hid, h.hid); }

    /** Resets this handle to a new value. */
    void reset(hid_t id = -1) throw ()
    {
            auto_handle<closer> tmp(id);
            swap(tmp);
    }

    /** Returns handle id */
    hid_t get() const throw () { return hid; }

    /** Releases handle id. This is an invalid handle afterwards. */
    hid_t release() throw () 
    {
        hid_t id = hid;
        hid = -1;
        return id;
    }
};

template <auto_handle_closer_t closer>
inline void swap(auto_handle<closer>& h1, auto_handle<closer>&h2)
{
    h1.swap(h2);
}

typedef auto_handle<H5Oclose> object_handle_t;
typedef auto_handle<H5Tclose> type_handle_t;
typedef auto_handle<H5Sclose> space_handle_t;
typedef auto_handle<H5Aclose> attr_handle_t;
typedef auto_handle<H5Fclose> file_handle_t;
typedef auto_handle<H5Dclose> dataset_handle_t;
typedef auto_handle<H5Pclose> plist_handle_t;
typedef auto_handle<H5Gclose> group_handle_t;

#endif // HDF5_AUTOHANDLE_INC
