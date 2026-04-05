import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
    title: 'QRBox – Smart Inventory for Your Boxes',
    description:
        'Scan a QR code to view the contents of a box. QRBox is a digital inventory system for physical storage boxes.',
};

export default function RootLayout({
    children,
}: {
    children: React.ReactNode;
}) {
    return (
        <html lang="en">
            <body>{children}</body>
        </html>
    );
}
