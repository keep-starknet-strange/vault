import dotenv from 'dotenv';
import twilio from 'twilio';
dotenv.config();

const accountSid = process.env.TWILIO_ACCOUNT_SID as string;
const authToken = process.env.TWILIO_AUTH_TOKEN as string;
const twilioNumber = process.env.TWILIO_PHONE_NUMBER as string;

const instance = twilio(accountSid, authToken);

export const sendMessage = async (otp: string, phone_number: string): Promise<boolean | Error> => {
  try {
    const res = await instance.messages.create({
      from: twilioNumber,
      to: phone_number,
      body: `Your OTP for verification for vault is ${otp}`,
    });

    if (res.sid) {
      return true;
    }

    return false;
    // biome-ignore lint: this is good enough
  } catch (error: any) {
    throw new Error(error);
  }
};
