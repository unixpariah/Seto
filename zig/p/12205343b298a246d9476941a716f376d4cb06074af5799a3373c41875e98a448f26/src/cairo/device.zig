//! `cairo.Device` — interface to underlying rendering system
//!
//! Devices are the abstraction Cairo employs for the rendering system used by
//! a `cairo.Surface`. You can get the device of a surface using
//! `surface.getDevice()`.
//!
//! Devices are created using custom functions specific to the rendering system
//! you want to use. See the documentation for the surface types for those
//! functions.
//!
//! An important function that devices fulfill is sharing access to the
//! rendering system between Cairo and your application. If you want to access
//! a device directly that you used to draw to with Cairo, you must first call
//! `device.flush()` to ensure that Cairo finishes all operations on the device
//! and resets it to a clean state.
//!
//! Cairo also provides the functions `device.acquire()` and `device.release()`
//! to synchronize access to the rendering system in a multithreaded
//! environment. This is done internally, but can also be used by applications.
//!
//! Putting this all together, a function that works with devices should look
//! something like this:
//! ```zig
//! fn myDeviceModifyintFunction(device: *cairo.Device) void {
//!     // Ensure the device is properly reset
//!     device.flush();
//!     // Try to acquire the device
//!     device.acquire() catch |e| {
//!         std.debug.print("Failed to acquire the device: {any}\n", .{e});
//!         return;
//!     };
//!
//!     // Do the custom operations on the device here.
//!     // But do not call any Cairo functions that might acquire devices.
//!
//!     // Release the device when done.
//!     device.release();
//! }
//! ```
//! >Please refer to the documentation of each backend for additional usage
//! requirements, guarantees provided, and interactions with existing surface
//! API of the device functions for surfaces of that type.
//!
//! [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-device-t.html)

const cairo = @import("../cairo.zig");
const c = cairo.c;
const safety = @import("safety");

const CairoError = cairo.CairoError;
const Status = cairo.Status;
const UserDataKey = cairo.UserDataKey;
const DestroyFn = cairo.DestroyFn;
const WriteFn = cairo.WriteFn;

pub fn Base(comptime Self: type) type {
    return struct {
        /// Cast an instance of `cairo.Device` to a base type
        pub fn asDevice(device: *Self) *Device {
            return @ptrCast(device);
        }

        /// Increases the reference count on `device` by one. This prevents
        /// device from being destroyed until a matching call to `.destroy()`
        /// is made.
        ///
        /// Use `cairo.Device.getReferenceCount()` to get the number of
        /// references to `device`.
        ///
        /// **Returns**
        ///
        /// the referenced device.
        ///
        /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-device-t.html#cairo-device-reference)
        pub fn reference(device: *Self) *Self {
            if (safety.tracing) safety.reference(@returnAddress(), device);
            return @ptrCast(c.cairo_device_reference(device).?);
        }

        /// Decreases the reference count on `device` by one. If the result is
        /// zero, then device and all associated resources are freed. See
        /// `cairo.Device.reference()`.
        ///
        /// This function may acquire devices if the last reference was
        /// dropped.
        ///
        /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-device-t.html#cairo-device-destroy)
        pub fn destroy(device: *Self) void {
            c.cairo_device_destroy(device);
            if (safety.tracing) safety.destroy(device);
        }

        /// Checks whether an error has previously occurred for this device.
        ///
        /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-device-t.html#cairo-device-status)
        pub fn status(device: *Self) Status {
            return c.cairo_device_status(device);
        }

        /// This function finishes the device and drops all references to
        /// external resources. All surfaces, fonts and other objects created
        /// for this device will be finished, too. Further operations on the
        /// device will not affect the device but will instead trigger a
        /// `cairo.Status.DeviceFinished` error.
        ///
        /// When the last call to `.destroy()` decreases the reference count to
        /// zero, cairo will call `.finish()` on `device` if it hasn't been
        /// called already, before freeing the resources associated with the
        /// device.
        ///
        /// This function may acquire devices.
        ///
        /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-device-t.html#cairo-device-finish)
        pub fn finish(device: *Self) void {
            c.cairo_device_finish(device);
        }

        /// Finish any pending operations for the device and also restore any
        /// temporary modifications cairo has made to the device's state. This
        /// function must be called before switching from using the device with
        /// Cairo to operating on it directly with native APIs. If the device
        /// doesn't support direct access, then this function does nothing.
        ///
        /// This function may acquire devices.
        ///
        /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-device-t.html#cairo-device-flush)
        pub fn flush(device: *Self) void {
            c.cairo_device_flush(device);
        }

        /// This function returns the type of the device. See
        /// `cairo.Device.Type` for available types.
        ///
        /// **Returns**
        ///
        /// the type of `device`.
        ///
        /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-device-t.html#cairo-device-get-type)
        pub fn getType(device: *Self) Device.Type {
            return c.cairo_device_get_type(device);
        }

        /// Returns the current reference count of `device`.
        ///
        /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-device-t.html#cairo-device-get-reference-count)
        pub fn getReferenceCount(device: *Self) usize {
            return @intCast(c.cairo_device_get_reference_count(device));
        }

        /// Attach user data to `device`. To remove user data from a device,
        /// call this function with the key that was used to set it and `null`
        /// for `data`.
        ///
        /// **Parameters**
        /// - `key`: the address of a `cairo.UserDataKey` to attach the user
        /// data to
        /// - `user_data`: the user data to attach to `device`
        /// - `destroyFn`: a `cairo.DestroyFn` which will be called when
        /// `device` is destroyed or when new user data is attached using the
        /// same key.
        ///
        /// The only possible error is `error.OutOfMemory` if a slot could not be
        /// allocated for the user data.
        ///
        /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-device-t.html#cairo-device-set-user-data)
        pub fn setUserData(device: *Self, key: *const UserDataKey, user_data: ?*anyopaque, destroyFn: DestroyFn) CairoError!void {
            return c.cairo_device_set_user_data(device, key, user_data, destroyFn).toErr();
        }

        /// Return user data previously attached to device using the specified key.
        /// If no user data has been attached with the given key this function
        /// returns `null`.
        ///
        /// **Parameters**
        /// - `key`: the address of the `cairo.UserDataKey` the user data was
        /// attached to
        ///
        /// **Returns**
        ///
        /// the user data previously attached or `null`.
        ///
        /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-device-t.html#cairo-device-get-user-data)
        pub fn getUserData(device: *Self, key: *const UserDataKey) ?*anyopaque {
            return c.cairo_device_get_user_data(device, key);
        }

        /// Acquires the device for the current thread. This function will block
        /// until no other thread has acquired the device.
        ///
        /// If the return value is `void`, you successfully acquired the device.
        /// From now on your thread owns the device and no other thread will be
        /// able to acquire it until a matching call to `.release()`. It is allowed
        /// to recursively acquire the device multiple times from the same thread.
        ///
        /// >You must never acquire two different devices at the same time unless
        /// this is explicitly allowed. Otherwise the possibility of deadlocks
        /// exist. As various Cairo functions can acquire devices when called,
        /// these functions may also cause deadlocks when you call them with an
        /// acquired device. So you must not have a device acquired when calling
        /// them. These functions are marked in the documentation.
        ///
        /// **Returns**
        /// `void` on success or an error if the device is in an error state and
        /// could not be acquired. After a successful call to `.acquire()`, a
        /// matching call to `.release()` is required.
        ///
        /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-device-t.html#cairo-device-acquire)
        pub fn acquire(device: *Self) CairoError!void {
            return c.cairo_device_acquire(device).toErr();
        }

        /// Releases a device previously acquired using `.acquire()`. See that
        /// function for details.
        ///
        /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-device-t.html#cairo-device-release)
        pub fn release(device: *Self) void {
            return c.cairo_device_release(device);
        }
    };
}

/// A `cairo.Device` represents the driver interface for drawing operations to
/// a `cairo.Surface`. There are different subtypes of `cairo.Device` for
/// different drawing backends; for example, `cairo.EglDevice.create()` creates
/// a device that wraps an EGL display and context.
///
/// The type of a device can be queried with `device.getType()`.
///
/// Memory management of `cairo.Device` is done with `device.reference()` and
/// `device.destroy()`.
///
/// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-device-t.html#cairo-device-t)
pub const Device = opaque {
    pub usingnamespace Base(@This());

    /// `cairo.Device.Type` is used to describe the type of a given device. The
    /// devices types are also known as "backends" within cairo.
    ///
    /// The device type can be queried with `cairo.Device.getType()`.
    ///
    /// The various `cairo.Device` functions can be used with devices of any
    /// type, but some backends also provide type-specific functions that must
    /// only be called with a device of the appropriate type. These functions
    /// are methids of specific `cairo.Device` instances such as
    /// `cairo.Script.writeComment()`.
    ///
    /// The behavior of calling a type-specific function with a device of the
    /// wrong type is undefined, that is — **DO NOT** cast pointers into
    /// `cairo.Device` manually, use `.asDevice()` on a specific type and **DO
    /// NOT** keep the result.
    ///
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-device-t.html#cairo-device-type-t)
    pub const Type = enum(c_int) {
        Drm = 0,
        Gl,
        Script,
        Xcb,
        Xlib,
        Xml,
        Cogl,
        Wn32,
        Invalid = -1,
    };

    // not sure what to do with these, they are undocumented, should consult
    // with cairomm or something

    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-device-t.html#cairo-device-observer-elapsed)
    pub fn observerElapsed(self: *Device) f64 {
        return c.cairo_device_observer_elapsed(self);
    }
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-device-t.html#cairo-device-observer-fill-elapsed)
    pub fn observerFillElapsed(self: *Device) f64 {
        return c.cairo_device_observer_fill_elapsed(self);
    }
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-device-t.html#cairo-device-observer-glyphs-elapsed)
    pub fn observerGlyphsElapsed(self: *Device) f64 {
        return c.cairo_device_observer_glyphs_elapsed(self);
    }
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-device-t.html#cairo-device-observer-mask-elapsed)
    pub fn observerMaskElapsed(self: *Device) f64 {
        return c.cairo_device_observer_mask_elapsed(self);
    }
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-device-t.html#cairo-device-observer-paint-elapsed)
    pub fn observerPaintElapsed(self: *Device) f64 {
        return c.cairo_device_observer_paint_elapsed(self);
    }
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-device-t.html#cairo-device-observer-print)
    pub fn observerPrint(self: *Device, write_func: WriteFn, closure: ?*anyopaque) CairoError!void {
        return c.cairo_device_observer_print(self, write_func, closure).toErr();
    }
    /// [Link to Cairo manual](https://www.cairographics.org/manual/cairo-cairo-device-t.html#cairo-device-observer-stroke-elapsed)
    pub fn observerStrokeElapsed(self: *Device) f64 {
        return c.cairo_device_observer_stroke_elapsed(self);
    }
};
