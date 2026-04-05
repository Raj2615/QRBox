const { onRequest } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const crypto = require("crypto");

admin.initializeApp();
const db = admin.firestore();

/**
 * Cloud Function: verifyPinAndGetBox
 *
 * Called by the public web viewer to verify a PIN and retrieve box contents.
 * This keeps pinHash server-side — never exposed to clients.
 *
 * Request body: { boxId: string, pin: string }
 * Response: { success: true, box: {...}, items: [...] } or error
 */
exports.verifyPinAndGetBox = onRequest(
  { cors: true, region: "us-central1" },
  async (req, res) => {
    // Only allow POST
    if (req.method !== "POST") {
      res.status(405).json({ success: false, error: "Method not allowed" });
      return;
    }

    const { boxId, pin } = req.body;

    // Validate input
    if (!boxId || !pin) {
      res
        .status(400)
        .json({ success: false, error: "boxId and pin are required" });
      return;
    }

    try {
      // Get the box document
      const boxDoc = await db.collection("boxes").doc(boxId).get();

      if (!boxDoc.exists) {
        res.status(404).json({ success: false, error: "Box not found" });
        return;
      }

      const boxData = boxDoc.data();

      // Check if box is configured
      if (!boxData.isConfigured) {
        res
          .status(400)
          .json({ success: false, error: "This box has not been set up yet" });
        return;
      }

      // Hash the submitted PIN and compare
      const pinHash = crypto.createHash("sha256").update(pin).digest("hex");

      if (pinHash !== boxData.pinHash) {
        res.status(401).json({ success: false, error: "Incorrect PIN" });
        return;
      }

      // PIN is correct — fetch items
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

      // Return box info + items (exclude sensitive fields)
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
      res
        .status(500)
        .json({ success: false, error: "Internal server error" });
    }
  }
);

/**
 * Cloud Function: forgotPin
 *
 * Called by the web viewer when a user forgets the PIN.
 * Verifies the email matches the box owner, then returns a PIN hint.
 *
 * Request body: { boxId: string, email: string }
 * Response: { success: true, message: "..." } or error
 */
exports.forgotPin = onRequest(
  { cors: true, region: "us-central1" },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ success: false, error: "Method not allowed" });
      return;
    }

    const { boxId, email } = req.body;

    if (!boxId || !email) {
      res
        .status(400)
        .json({ success: false, error: "boxId and email are required" });
      return;
    }

    try {
      // Get the box document
      const boxDoc = await db.collection("boxes").doc(boxId).get();

      if (!boxDoc.exists) {
        res.status(404).json({ success: false, error: "Box not found" });
        return;
      }

      const boxData = boxDoc.data();

      // Get the owner's user document
      const userDoc = await db.collection("users").doc(boxData.ownerId).get();

      if (!userDoc.exists) {
        res
          .status(404)
          .json({ success: false, error: "Box owner not found" });
        return;
      }

      const userData = userDoc.data();

      // Verify email matches the owner
      if (
        userData.email &&
        userData.email.toLowerCase() === email.toLowerCase()
      ) {
        // For security, we don't send the actual PIN
        // Instead, we send a hint (first and last digit)
        // The owner would need to check the app to reset the PIN
        res.status(200).json({
          success: true,
          message:
            "Email verified! For security, please open the QRBox app to view or reset your PIN. If you cannot access the app, contact support.",
        });
      } else {
        res.status(401).json({
          success: false,
          error:
            "The email does not match the box owner's account.",
        });
      }
    } catch (error) {
      console.error("Error in forgotPin:", error);
      res
        .status(500)
        .json({ success: false, error: "Internal server error" });
    }
  }
);
