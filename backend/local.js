const app = require('./api/index');

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Server is running locally on http://localhost:${PORT}`);
  console.log('Ensure you have your .env variables set for Razorpay to work properly.');
});
