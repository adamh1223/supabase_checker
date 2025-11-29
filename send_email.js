import nodemailer from "nodemailer";

const { EMAIL_FROM, EMAIL_TO, EMAIL_PASS, EMAIL_USER } = process.env;

async function sendEmail(subject, msg) {
  const transporter = nodemailer.createTransport({
    service: "gmail",
    auth: {
      user: EMAIL_USER,
      pass: EMAIL_PASS,
    },
  });

  await transporter.sendMail({
    from: EMAIL_FROM,
    to: EMAIL_TO,
    subject,
    text: msg,
  });
}

const subject = process.argv[2] || "Supabase Ping Failed";
const message = process.argv[3] || "The ping script reported a failure.";

sendEmail(subject, message)
  .then(() => console.log("Email sent!"))
  .catch((err) => console.error("Failed to send email:", err));
