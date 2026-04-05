export default function Home() {
    return (
        <div className="container center-content">
            <div className="logo-wrapper">
                <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                    <path d="M3 11h8V3H3v8zm2-6h4v4H5V5zm8-2v8h8V3h-8zm6 6h-4V5h4v4zM3 21h8v-8H3v8zm2-6h4v4H5v-4zm13 2h2v4h-4v-2h2v-2zm-3-2h2v2h-2v-2zm-2 4h2v2h-2v-2zm2 2h2v2h-2v-2zm2-2h2v2h-2v-2zm2-4h2v4h-2v-4zm0-2h2v2h-2v-2zm-4 0h2v2h-2v-2z" />
                </svg>
            </div>
            <h1 className="app-title">QRBox</h1>
            <p className="app-subtitle">
                Smart Inventory for Your Boxes
            </p>
            <div className="card" style={{ maxWidth: 360 }}>
                <p style={{ fontSize: 14, color: 'var(--color-text-secondary)', lineHeight: 1.6 }}>
                    Scan a QR code on any box to view its contents. Each QR code links
                    directly to a box&apos;s inventory page.
                </p>
            </div>
            <div className="footer">
                <p>Powered by <a href="#">QRBox</a></p>
            </div>
        </div>
    );
}
