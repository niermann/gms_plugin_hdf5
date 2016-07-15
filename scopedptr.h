#ifndef HDF5_SCOPEDPTR_INC
#define HDF5_SCOPEDPTR_INC

#include <hdf5.h>
#include <algorithm>
#include <vector>

typedef void (*dealloc_t)(void*);

/**
 * A class, that automatically deletes/frees a pointer when destroyed.
 */
template <class T, dealloc_t dealloc> class scoped_ptr
{
private:
    // No copy
    scoped_ptr(const scoped_ptr&);
    scoped_ptr& operator=(const scoped_ptr&);

    T* ptr;

public:
    /** Default CTOR: Creates NULL pointer. */
    scoped_ptr() throw (): ptr(NULL) {}

    /** Create scoped ptr from pointer. */
    explicit scoped_ptr(T* ptr_in) throw (): ptr(ptr_in) {}

    // DTOR
    ~scoped_ptr() throw () 
    { 
        T* tmp = ptr;
        if (tmp) {
            ptr = NULL;
            dealloc(ptr); 
        }
    }

    /** Returns true, if this is a valid pointer */
    bool valid() const throw () { return !!ptr; }

    /** Swaps pointers. */
    void swap(scoped_ptr<T, dealloc>& other) throw () { std::swap(ptr, other.ptr); }

    /** Resets this pointer to a new value. */
    void reset(T* ptr_in = NULL) throw ()
    {
            scoped_ptr<T, dealloc> tmp(ptr_in);
            swap(tmp);
    }

    /** Returns handle id */
    T* get() const throw () { return ptr; }

    /** Releases handle id. This is a NULL afterwards. */
    T* release() throw () 
    {
        T* tmp = ptr;
        ptr = NULL;
        return tmp;
    }

    // Dereference ptr
    T* operator->()const { return ptr; }
    T& operator*()const { return *ptr; }
};

template <class T, dealloc_t D> inline void swap(scoped_ptr<T, D>& a, scoped_ptr<T, D>& b)
{
    a.swap(b);
}

/**
 * A class, that automatically deletes/frees a pointers when destroyed.
 */
template <class T, dealloc_t dealloc> class scoped_ptr_array
{
private:
    // No default
    scoped_ptr_array();

    // No copy
    scoped_ptr_array(const scoped_ptr_array&);
    scoped_ptr_array& operator=(const scoped_ptr_array&);

    std::vector<T*> data;

public:
    /** Create vector with num NULL entries. */
    explicit scoped_ptr_array(std::size_t num) throw (): data(num, static_cast<T*>(NULL)) {}

    // DTOR
    ~scoped_ptr_array() throw () 
    {
        std::vector<T*>::iterator iter = data.begin();
        std::vector<T*>::iterator end = data.end();
        while (iter != end) {
            T* tmp = *iter;
            *iter = NULL;
            dealloc(tmp);
            ++iter;
        }
    }

    /** Return size of array. */
    std::size_t size() const { return data.size(); }

    /** Return whether array is empty. */
    bool empty() const { return data.empty(); }

    // Iteration
    typedef typename std::vector<T*>::const_iterator const_iterator;
    const_iterator begin() const { return data.begin(); }
    const_iterator end() const { return data.end(); }

    /** Access to underlying array, use with care */
    T** unsafe_data() { return &data[0]; }

    /** Swaps vectors. */
    void swap(scoped_ptr_array<T, dealloc>& other) throw () { data.swap(other); }

    /** Returns pointer at index */
    T* get(std::size_t index) const throw () { return index < data.size() ? data[index] : NULL; }

    /** Sets pointer at index, clearing previous value */
    void set(std::size_t index, T* ptr) const throw () 
    {
        if (index < data.size()) {
            T* tmp = data[index];
            data[index] = ptr;
            deleter(tmp);
        } else
            deleter(ptr);
    }

    /** Releases pointer at index. Is is NULL afterwards. */
    T* release(std::size_t index) throw () 
    {
        if (index >= data.size())
            return NULL;

        T* tmp = data[index];
        data[index] = NULL;
        return tmp;
    }
};

template <class T, dealloc_t D> inline void swap(scoped_ptr_array<T, D>& a, scoped_ptr_array<T, D>& b)
{
    a.swap(b);
}

#endif // HDF5_SCOPEDPTR_INC
