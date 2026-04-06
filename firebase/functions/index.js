const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const crypto = require("crypto");

admin.initializeApp();
const db = admin.firestore();

// Allowed origins for CORS
const ALLOWED_ORIGINS = [
  "https://qrbox-cbcbb.web.app",
  "https://qrbox-cbcbb.firebaseapp.com",
  "http://localhost:3000",
  "http://localhost:5000",
  "http://127.0.0.1:5000",
];

function setCorsHeaders(req, res) {
  const origin = req.headers.origin;
  if (ALLOWED_ORIGINS.includes(origin)) {
    res.set("Access-Control-Allow-Origin", origin);
  } else {
    // Allow all in development / unknown origins
    res.set("Access-Control-Allow-Origin", "*");
  }
  res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type, Authorization");
  res.set("Access-Control-Max-Age", "3600");
}

/**
 * Cloud Function: verifyPinAndGetBox
 */
exports.verifyPinAndGetBox = onRequest(
  { region: "us-central1" },
  async (req, res) => {
    setCorsHeaders(req, res);

    // Handle CORS preflight
    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    // Only allow POST
    if (req.method !== "POST") {
      res.status(405).json({ success: false, error: "Method not allowed" });
      return;
    }

    const { boxId, pin } = req.body;

    if (!boxId || !pin) {
      res.status(400).json({ success: false, error: "boxId and pin are required" });
      return;
    }

    try {
      const boxDoc = await db.collection("boxes").doc(boxId).get();

      if (!boxDoc.exists) {
        res.status(404).json({ success: false, error: "Box not found" });
        return;
      }

      const boxData = boxDoc.data();

      if (!boxData.isConfigured) {
        res.status(400).json({ success: false, error: "This box has not been set up yet" });
        return;
      }

      const pinHash = crypto.createHash("sha256").update(pin).digest("hex");

      if (pinHash !== boxData.pinHash) {
        res.status(401).json({ success: false, error: "Incorrect PIN" });
        return;
      }

      const itemsSnapshot = await db
        .collection("items")
        .where("boxId", "==", boxId)
        .get();

      const items = itemsSnapshot.docs.map((doc) => ({
        id: doc.id,
        name: doc.data().name,
        quantity: doc.data().quantity,
        description: doc.data().description || null,
        imageUrl: doc.data().imageUrl || null,
      }));

      res.status(200).json({
        success: true,
        box: {
          id: boxDoc.id,
          name: boxData.name,
          location: boxData.location,
          description: boxData.description || null,
          itemCount: boxData.itemCount || 0,
        },
        items: items,
      });
    } catch (error) {
      console.error("Error in verifyPinAndGetBox:", error);
      res.status(500).json({ success: false, error: "Internal server error" });
    }
  }
);


/**
 * Cloud Function: forgotPin
 */
exports.forgotPin = onRequest(
  { region: "us-central1" },
  async (req, res) => {
    setCorsHeaders(req, res);

    if (req.method === "OPTIONS") {
      res.status(204).send("");
      return;
    }

    if (req.method !== "POST") {
      res.status(405).json({ success: false, error: "Method not allowed" });
      return;
    }

    const { boxId, email } = req.body;

    if (!boxId || !email) {
      res.status(400).json({ success: false, error: "boxId and email are required" });
      return;
    }

    try {
      const boxDoc = await db.collection("boxes").doc(boxId).get();

      if (!boxDoc.exists) {
        res.status(404).json({ success: false, error: "Box not found" });
        return;
      }

      const boxData = boxDoc.data();

      const userDoc = await db.collection("users").doc(boxData.ownerId).get();

      if (!userDoc.exists) {
        res.status(404).json({ success: false, error: "Box owner not found" });
        return;
      }

      const userData = userDoc.data();

      if (userData.email && userData.email.toLowerCase() === email.toLowerCase()) {
        res.status(200).json({
          success: true,
          message: "Email verified! For security, please open the QRBox app to view or reset your PIN.",
        });
      } else {
        res.status(401).json({
          success: false,
          error: "The email does not match the box owner's account.",
        });
      }
    } catch (error) {
      console.error("Error in forgotPin:", error);
      res.status(500).json({ success: false, error: "Internal server error" });
    }
  }
);

