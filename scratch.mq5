// scratch.mq5
#property script_show_inputs

void SolveDIAD(double L0, double targetAmt, double V,
                                double P0, double P1, double P2, double P3,
                                double E1, double E2, double E3,
                                double S1, double S2, double S3)
{
   double M1 = S1 - E1;
   double M2 = S2 - E2;
   double M3 = S3 - E3;
   
   double A1 = 1.0 / M1;
   double B1 = -(L0 * S1) / M1;
   
   double A2 = (1.0 - A1 * (S2 - E1)) / M2;
   double B2 = -(L0 * S2 + B1 * (S2 - E1)) / M2;
   
   double A3 = (1.0 - A1 * (S3 - E1) - A2 * (S3 - E2)) / M3;
   double B3 = -(L0 * S3 + B1 * (S3 - E1) + B2 * (S3 - E2)) / M3;
   
   double denominator = A1 * P1 + A2 * P2 + A3 * P3;
   double RHS = (targetAmt / V) - L0 * P0;
   double numerator = RHS - (B1 * P1 + B2 * P2 + B3 * P3);
   double X = numerator / denominator;
   
   double L1 = A1 * X + B1;
   double L2 = A2 * X + B2;
   double L3 = A3 * X + B3;
   double C  = X * V;
   
   PrintFormat("L1=%.4f L2=%.4f L3=%.4f C=%.2f", L1, L2, L3, C);
}

void OnStart()
{
   // T = 1000 pips (10 dollars)
   // L0 = 1.14
   // Target = 17200
   SolveDIAD(1.14, 17200, 1.0, 1000, 650, 500, 350, 350, 500, 650, 250, 400, 550);
}
