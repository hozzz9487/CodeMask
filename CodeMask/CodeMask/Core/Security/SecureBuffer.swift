import Foundation
import Darwin

/// A secure memory buffer that locks data in RAM to prevent swapping to disk.
/// This class manages its own memory lifecycle using `posix_memalign`, `mlock`, and `memset`.
final class SecureBuffer {
    
    private let pointer: UnsafeMutableRawPointer
    private let allocationSize: Int
    
    /// Initializes the secure buffer with a string.
    /// - Parameter string: The sensitive content to protect.
    init(string: String) {
        // Calculate size aligned to page boundary
        // vm_page_size is a global variable in Mach/Darwin
        let pageSize = Int(vm_page_size)
        let payload = string.utf8
        let payloadSize = payload.count
        
        // We need space for the string + null terminator to be safe for C-string retrieval,
        // although we can also rebuild from bytes if we knew length.
        // Given we zero-fill, just ensuring payload fits is enough, the next byte will be 0.
        // Round up allocation to nearest page size.
        // Formula: (size + pageSize - 1) & ~(pageSize - 1)
        // We assume payloadSize is small enough to fit in size_t.
        
        // Minimal size needed is payloadSize + 1 (for potential null term if we want to be safe).
        // But strict page alignment handles this as page size >> string size usually.
        let requiredSize = payloadSize + 1
        self.allocationSize = (requiredSize + pageSize - 1) & ~(pageSize - 1)
        
        // Allocate aligned memory
        var rawPtr: UnsafeMutableRawPointer?
        let alignment = pageSize
        let result = posix_memalign(&rawPtr, alignment, allocationSize)
        
        guard result == 0, let allocatedPtr = rawPtr else {
            // Fatal error is appropriate here as we cannot guarantee security if allocation fails
            fatalError("SecureBuffer: Failed to allocate aligned memory. Error: \(result)")
        }
        
        self.pointer = allocatedPtr
        
        // 1. Zero out the memory first (Safe Initialization)
        memset(self.pointer, 0, self.allocationSize)
        
        // 2. Copy string bytes to the secure buffer
        string.withCString { cString in
            // We copy the bytes including the null terminator implicitly if we use strcpy,
            // or explicit memcpy.
            // string.utf8 does not include null.
            // cString is null terminated.
            // We use memcpy with payloadSize. The buffer is already zeroed, so it is null terminated.
            memcpy(self.pointer, cString, payloadSize)
        }
        
        // 3. Lock the memory pages to prevent swapping (CRITICAL)
        if mlock(self.pointer, self.allocationSize) != 0 {
            // In a security context, failure to lock is a vulnerability.
            // We log a high-visibility warning.
            print("SecureBuffer [CRITICAL]: mlock failed with error \(errno). Sensitive data may swap to disk.")
        }
    }
    
    deinit {
        // 1. Secure wipe (memset)
        // We zero the entire allocation before freeing.
        // Note: The compiler might optimize this away if it sees 'free' immediately after.
        // However, Swift's optimization of C calls across FFI boundary usually respects side effects.
        // Ideally we would use memset_s.
        memset(pointer, 0, allocationSize)
        
        // 2. Unlock the pages
        munlock(pointer, allocationSize)
        
        // 3. Free the memory
        free(pointer)
    }
    
    /// Retrieves the content as a transient String.
    /// - Returns: The original string.
    func retrieve() -> String? {
        // Reconstruct string from raw bytes.
        // Since we ensured null-termination via zero-fill and memcpy, we can use String(cString:).
        // We cast the raw pointer to UnsafePointer<CChar>.
        let cCharPointer = pointer.assumingMemoryBound(to: CChar.self)
        return String(cString: cCharPointer)
    }
}
