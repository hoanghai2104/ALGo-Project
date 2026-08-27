codeunit 50115 TransferNoIntervention
{
    Subtype = Upgrade;
    ObsoleteState = Pending;
    ObsoleteReason = 'To be removed after upgrade';
    // trigger OnUpgradePerCompany()
    // var
    //     receptionAchatRec: Record "DetailReceptionAchat";
    // begin
    //     receptionAchatRec.Reset();
    //     if receptionAchatRec.FindSet() then
    //         repeat
    //             if receptionAchatRec.InterventionNo = '' then
    //                 continue;
    //             receptionAchatRec."No de intervention" := receptionAchatRec."InterventionNo";
    //             receptionAchatRec.Modify();
    //         until receptionAchatRec.Next() = 0;
    // end;




}