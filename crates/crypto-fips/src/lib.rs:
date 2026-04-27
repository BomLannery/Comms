#![no_std] // No standard library = smaller attack surface & better for Space

use wolfssl_sys as wolf; // FIPS-validated C bindings

use core::ffi::c_int;

/// Custom error type for Lunar operations
#[derive(Debug)]
pub enum LunarCryptoError {
    FipsNotReady,
    ContextCreationFailed,
    HandshakeFailed(c_int),
    InitFailed,
}

pub struct FipsContext {
    ctx: *mut wolf::WOLFSSL_CTX,
}

impl FipsContext {
    /// Initialize the Zynq Hardware Crypto Engine and FIPS 140-3 environment
    pub fn initialize() -> Result<Self, LunarCryptoError> {
        unsafe {
            // Initialize the library
            if wolf::wolfSSL_Init() != wolf::WOLFSSL_SUCCESS {
                return Err(LunarCryptoError::InitFailed);
            }

            // Verify FIPS 140-3 status (Checks Zynq PUF/Hard-Cores)
            if wolf::wolfcrypt_FIPS_ready() == 0 {
                return Err(LunarCryptoError::FipsNotReady);
            }

            // Create a TLS 1.3 Context (Lunanet standard)
            let method = wolf::wolfTLSv1_3_client_method();
            let ctx = wolf::wolfSSL_CTX_new(method);
            
            if ctx.is_null() {
                return Err(LunarCryptoError::ContextCreationFailed);
            }

            Ok(Self { ctx })
        }
    }

    /// Creates a secure session handle (The actual "wrapper" object)
    pub fn new_session(&self) -> Result<SecureSession, LunarCryptoError> {
        unsafe {
            let ssl = wolf::wolfSSL_new(self.ctx);
            if ssl.is_null() {
                return Err(LunarCryptoError::ContextCreationFailed);
            }
            Ok(SecureSession { ssl })
        }
    }
}

pub struct SecureSession {
    ssl: *mut wolf::WOLFSSL,
}

impl SecureSession {
    /// Bind the session to the File Descriptor of your Virtual Patch Cable
    pub fn bind_veth_fd(&mut self, fd: c_int) {
        unsafe {
            wolf::wolfSSL_set_fd(self.ssl, fd);
        }
    }

    /// Perform the secure handshake across the lunar segment
    pub fn establish(&mut self) -> Result<(), LunarCryptoError> {
        unsafe {
            let ret = wolf::wolfSSL_connect(self.ssl);
            if ret != wolf::WOLFSSL_SUCCESS {
                return Err(LunarCryptoError::HandshakeFailed(ret));
            }
            Ok(())
        }
    }

    /// High-level encrypted write for O2 manifest data
    pub fn encrypted_send(&mut self, data: &[u8]) -> c_int {
        unsafe {
            wolf::wolfSSL_write(
                self.ssl,
                data.as_ptr() as *const _,
                data.len() as c_int,
            )
        }
    }
}

// Ensure resources are cleaned up (RAII)
impl Drop for SecureSession {
    fn drop(&mut self) {
        unsafe { wolf::wolfSSL_free(self.ssl); }
    }
}
