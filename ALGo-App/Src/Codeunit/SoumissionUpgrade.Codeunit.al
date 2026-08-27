codeunit 50112 SoumissionUpgrade
{
    Subtype = Upgrade;
    ObsoleteState = Pending;
    ObsoleteReason = 'To be removed after upgrade';
    trigger OnRun()
    begin

    end;

    // trigger OnUpgradePerCompany()
    // begin
    //     // CalBaseUnitPrice();
    // end;

    // procedure CalBaseUnitPrice()
    // var
    //     SoumissionLine: Record SoumissionLine;
    // begin
    //     SoumissionLine.Reset();
    //     SoumissionLine.SetAutoCalcFields("Unit Price");
    //     if SoumissionLine.FindSet() then
    //         repeat
    //             SoumissionLine."Unit Price (base)" := SoumissionLine."Unit Price";
    //             if SoumissionLine.Modify() then;
    //         until SoumissionLine.Next() = 0;
    // end;


}