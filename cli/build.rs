fn main() {
    // VERSIONINFO metadata for the Windows exe, mirroring app/windows/runner/Runner.rc.
    // SignPath requires ProductName/ProductVersion on all signed binaries.
    if std::env::var_os("CARGO_CFG_WINDOWS").is_some() {
        let mut res = winresource::WindowsResource::new();
        res.set("ProductName", "Linko");
        res.set("FileDescription", "Linko CLI");
        res.set("CompanyName", "Linko");
        res.set("OriginalFilename", "linko-cli.exe");
        res.set("InternalName", "linko-cli");
        res.set("LegalCopyright", "Copyright (C) 2022-2026 Linko");
        // FileVersion/ProductVersion are derived from CARGO_PKG_VERSION automatically.
        res.compile().expect("failed to compile Windows resources");
    }
}