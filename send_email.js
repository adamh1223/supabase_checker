require("dotenv").config();
const nodemailer = require("nodemailer");

async function sendEmail(subject, msg) {
  const transporter = nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASS,
    },
  });

  await transporter.sendMail({
    from: process.env.EMAIL_FROM,
    to: process.env.EMAIL_TO,
    subject,
    text: msg,
  });
}

const subject = process.argv[2] || "Supabase Ping Failed";
const message = process.argv[3] || "The ping script reported a failure.";

sendEmail(subject, message)
  .then(() => console.log("Email sent!"))
  .catch((err) => console.error("Failed to send email:", err));
