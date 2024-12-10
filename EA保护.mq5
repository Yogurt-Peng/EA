//+------------------------------------------------------------------+
//|                                      KeyGeneratorProtectedEA.mq5 |
//|                                      Copyright 2012, Investeo.pl |
//|                                           http://www.investeo.pl |
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, Investeo.pl"
#property link      "http://www.investeo.pl"
#property version   "1.00"

#include <ChartObjects/ChartObjectsTxtControls.mqh>
#include <Strings/String.mqh>

CChartObjectEdit password_edit;
CString user_pass;

const double divisor_sequence[] = { 3.0, 4.0, 5.0 };
                             
int    password_status = -1;
string password_message[] = { "WRONG PASSWORD. Trading not allowed.",
                         "EA PASSWORD verified." };

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   password_edit.Create(0, "password_edit", 0, 10, 10, 260, 25);
   password_edit.BackColor(White);
   password_edit.BorderColor(Black);
   password_edit.SetInteger(OBJPROP_SELECTED, 0, true);
//---
   return(0);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   password_edit.Delete();
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
  if (password_status==3) 
  {
    // password correct
  } 
  }
  
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---
   if (id == CHARTEVENT_OBJECT_ENDEDIT && sparam == "password_edit" )
      {
         password_status = 0;
         
         user_pass.Assign(password_edit.GetString(OBJPROP_TEXT));

         int hyphen_1 = user_pass.Find(0, "-");
         int hyphen_2 = user_pass.FindRev("-");
         
         if (hyphen_1 == -1 || hyphen_2 == -1 || hyphen_1 == hyphen_2) {
            password_edit.SetString(OBJPROP_TEXT, 0, password_message[0]);
            return;
         } ;     
         
         long pass_1 = StringToInteger(user_pass.Mid(0, hyphen_1));
         long pass_2 = StringToInteger(user_pass.Mid(hyphen_1 + 1, hyphen_2));
         long pass_3 = StringToInteger(user_pass.Mid(hyphen_2 + 1, StringLen(user_pass.Str())));
         
         // PrintFormat("%d : %d : %d", pass_1, pass_2, pass_3);
         
         if (MathIsValidNumber(pass_1) && MathMod((double)pass_1, divisor_sequence[0]) == 0.0) password_status++;
         if (MathIsValidNumber(pass_2) && MathMod((double)pass_2, divisor_sequence[1]) == 0.0) password_status++;
         if (MathIsValidNumber(pass_3) && MathMod((double)pass_3, divisor_sequence[2]) == 0.0) password_status++;
            
         if (password_status != 3) 
            password_edit.SetString(OBJPROP_TEXT, 0, password_message[0]);
         else
            password_edit.SetString(OBJPROP_TEXT, 0, password_message[1]); 
      }
  }
//+------------------------------------------------------------------+