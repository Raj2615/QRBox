'use client';

import { useState, useRef, useEffect } from 'react';

// ─── Types ──────────────────────────────────────────────────────────

interface BoxData {
    id: string;
    name: string;
    location: string;
    description: string | null;
    itemCount: number;
}

interface ItemData {
    id: string;
    name: string;
    quantity: number;
    description: string | null;
    imageUrl: string | null;
}

// ─── Config ─────────────────────────────────────────────────────────

// In production, this would be your Firebase Functions URL:
// https://us-central1-YOUR_PROJECT.cloudfunctions.net/verifyPinAndGetBox
// During development, use the emulator URL or a placeholder:
const API_URL =
    process.env.NEXT_PUBLIC_API_URL ||
    'https://us-central1-qrbox-app.cloudfunctions.net/verifyPinAndGetBox';

// ─── Page Component ─────────────────────────────────────────────────

export default function BoxPage({ params }: { params: { boxId: string } }) {
    const { boxId } = params;
    const [state, setState] = useState<'pin' | 'loading' | 'inventory' | 'error'>(
        'pin'
    );
    const [box, setBox] = useState<BoxData | null>(null);
    const [items, setItems] = useState<ItemData[]>([]);
    const [error, setError] = useState('');

    async function handlePinSubmit(pin: string) {
        setState('loading');
        setError('');

        try {
            const res = await fetch(API_URL, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ boxId, pin }),
            });

            const data = await res.json();

            if (!res.ok || !data.success) {
                setError(data.error || 'Incorrect PIN. Please try again.');
                setState('pin');
                return;
            }

            setBox(data.box);
            setItems(data.items || []);
            setState('inventory');
        } catch (e) {
            setError('Unable to connect. Please check your internet connection.');
            setState('pin');
        }
    }

    return (
        <div className="container">
            {/* Header */}
            <div style={{ textAlign: 'center', paddingTop: 20, marginBottom: 8 }}>
                <div className="logo-wrapper" style={{ margin: '0 auto 12px' }}>
                    <svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                        <path d="M3 11h8V3H3v8zm2-6h4v4H5V5zm8-2v8h8V3h-8zm6 6h-4V5h4v4zM3 21h8v-8H3v8zm2-6h4v4H5v-4zm13 2h2v4h-4v-2h2v-2zm-3-2h2v2h-2v-2zm-2 4h2v2h-2v-2zm2 2h2v2h-2v-2zm2-2h2v2h-2v-2zm2-4h2v4h-2v-4zm0-2h2v2h-2v-2zm-4 0h2v2h-2v-2z" />
                    </svg>
                </div>
                <p
                    style={{
                        fontSize: 12,
                        color: 'var(--color-text-secondary)',
                        fontFamily: 'monospace',
                        marginBottom: 4,
                    }}
                >
                    {boxId}
                </p>
            </div>

            {/* PIN Entry State */}
            {(state === 'pin' || state === 'loading') && (
                <div className="center-content" style={{ flex: 'unset' }}>
                    <PinEntry
                        onSubmit={handlePinSubmit}
                        error={error}
                        isLoading={state === 'loading'}
                    />
                </div>
            )}

            {/* Inventory State */}
            {state === 'inventory' && box && (
                <InventoryDisplay box={box} items={items} />
            )}

            {/* Footer */}
            <div className="footer">
                <p>
                    Powered by <a href="/">QRBox</a>
                </p>
            </div>
        </div>
    );
}

// ─── PIN Entry Component ────────────────────────────────────────────

function PinEntry({
    onSubmit,
    error,
    isLoading,
}: {
    onSubmit: (pin: string) => void;
    error: string;
    isLoading: boolean;
}) {
    const [digits, setDigits] = useState(['', '', '', '']);
    const inputRefs = useRef<(HTMLInputElement | null)[]>([]);

    useEffect(() => {
        inputRefs.current[0]?.focus();
    }, []);

    function handleChange(index: number, value: string) {
        if (!/^\d*$/.test(value)) return;

        const newDigits = [...digits];
        newDigits[index] = value.slice(-1);
        setDigits(newDigits);

        if (value && index < 3) {
            inputRefs.current[index + 1]?.focus();
        }

        // Auto-submit when all digits entered
        const pin = newDigits.join('');
        if (pin.length === 4 && newDigits.every((d) => d !== '')) {
            onSubmit(pin);
        }
    }

    function handleKeyDown(index: number, e: React.KeyboardEvent) {
        if (e.key === 'Backspace' && !digits[index] && index > 0) {
            inputRefs.current[index - 1]?.focus();
        }
    }

    function handleSubmit(e: React.FormEvent) {
        e.preventDefault();
        const pin = digits.join('');
        if (pin.length === 4) {
            onSubmit(pin);
        }
    }

    return (
        <div className="card" style={{ maxWidth: 360, margin: '0 auto' }}>
            <h2 className="card-header">Enter PIN</h2>
            <p className="card-subheader">
                Enter the 4-digit PIN to view this box&apos;s contents
            </p>

            {error && <p className="error-message">{error}</p>}

            <form onSubmit={handleSubmit}>
                <div className="pin-group">
                    {digits.map((digit, i) => (
                        <input
                            key={i}
                            ref={(el) => { inputRefs.current[i] = el; }}
                            type="text"
                            inputMode="numeric"
                            maxLength={1}
                            className="pin-input"
                            value={digit}
                            onChange={(e) => handleChange(i, e.target.value)}
                            onKeyDown={(e) => handleKeyDown(i, e)}
                            disabled={isLoading}
                            autoComplete="off"
                        />
                    ))}
                </div>

                <button
                    type="submit"
                    className="btn btn-primary"
                    disabled={isLoading || digits.some((d) => d === '')}
                >
                    {isLoading ? (
                        <>
                            <span className="spinner" />
                            Verifying...
                        </>
                    ) : (
                        <>
                            <svg
                                width="18"
                                height="18"
                                viewBox="0 0 24 24"
                                fill="currentColor"
                            >
                                <path d="M18 8h-1V6c0-2.76-2.24-5-5-5S7 3.24 7 6v2H6c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V10c0-1.1-.9-2-2-2zM12 17c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2zm3.1-9H8.9V6c0-1.71 1.39-3.1 3.1-3.1 1.71 0 3.1 1.39 3.1 3.1v2z" />
                            </svg>
                            Unlock
                        </>
                    )}
                </button>
            </form>
        </div>
    );
}

// ─── Inventory Display Component ────────────────────────────────────

function InventoryDisplay({
    box,
    items,
}: {
    box: BoxData;
    items: ItemData[];
}) {
    return (
        <div style={{ flex: 1 }}>
            {/* Box Header */}
            <div className="box-header">
                <h1 className="box-name">{box.name}</h1>
                <div className="box-meta">
                    <span className="meta-chip">
                        <svg viewBox="0 0 24 24">
                            <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z" />
                        </svg>
                        {box.location || 'Unknown'}
                    </span>
                    {box.description && (
                        <span className="meta-chip">
                            <svg viewBox="0 0 24 24">
                                <path d="M14 2H6c-1.1 0-2 .9-2 2v16c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V8l-6-6zm-1 9h-2v2H9v-2H7V9h2V7h2v2h2v2zm-1-7.5L17.5 9H12V3.5z" />
                            </svg>
                            {box.description}
                        </span>
                    )}
                </div>
            </div>

            {/* Items */}
            <div className="items-section">
                <div className="items-title">
                    Items
                    <span className="items-count">{items.length}</span>
                </div>

                {items.length === 0 ? (
                    <div className="empty-state">
                        <svg viewBox="0 0 24 24">
                            <path d="M20 2H4c-1.1 0-2 .9-2 2v16c0 1.1.9 2 2 2h16c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2zM8 20H4v-4h4v4zm0-6H4v-4h4v4zm0-6H4V4h4v4zm6 12h-4v-4h4v4zm0-6h-4v-4h4v4zm0-6h-4V4h4v4zm6 12h-4v-4h4v4zm0-6h-4v-4h4v4zm0-6h-4V4h4v4z" />
                        </svg>
                        <p>This box is empty</p>
                    </div>
                ) : (
                    items.map((item) => (
                        <div key={item.id} className="item-card">
                            {item.imageUrl ? (
                                <img
                                    src={item.imageUrl}
                                    alt={item.name}
                                    className="item-image"
                                />
                            ) : (
                                <div className="item-icon">
                                    <svg viewBox="0 0 24 24">
                                        <path d="M12 2l-5.5 9h11L12 2zm0 3.84L13.93 9h-3.87L12 5.84zM17.5 13c-2.49 0-4.5 2.01-4.5 4.5s2.01 4.5 4.5 4.5 4.5-2.01 4.5-4.5-2.01-4.5-4.5-4.5zm0 7c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5zM3 21.5h8v-8H3v8zm2-6h4v4H5v-4z" />
                                    </svg>
                                </div>
                            )}

                            <div className="item-info">
                                <div className="item-name">{item.name}</div>
                                {item.description && (
                                    <div className="item-desc">{item.description}</div>
                                )}
                            </div>

                            <div className="item-qty">x{item.quantity}</div>
                        </div>
                    ))
                )}
            </div>
        </div>
    );
}
