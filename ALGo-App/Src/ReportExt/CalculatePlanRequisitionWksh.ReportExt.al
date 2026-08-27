reportextension 50111 "Calc. Plan - Req. Wksh. Ext." extends "Calculate Plan - Req. Wksh."
{
    requestpage
    {
        layout
        {
            addlast(Options)
            {
                field(ToOrderFilter; ToOrderFilter)
                {
                    Caption = 'To Order';
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Utilities.DisposeNotification(GlobalNotification);

                        if ToOrderFilter in [ToOrderFilter::Yes, ToOrderFilter::No] then
                            Utilities.SendNotification(SalesServiceOrderSearchLimitLbl, NotificationScope::LocalScope, GlobalNotification);
                    end;
                }
            }
        }
    }

    trigger OnPreReport()
    begin
        RequisitionWkshFilterState.SetToOrderMode(ToOrderFilter);
    end;

    trigger OnPostReport()
    begin
        //Clear state after report execution to avoid affecting other reports or processes
        RequisitionWkshFilterState.Dispose();
    end;

    var
        RequisitionWkshFilterState: Codeunit "Requisition Wksh. Filter State";
        Utilities: Codeunit Utilities;
        ToOrderFilter: Enum "Requisition Wksh. To Order";
        GlobalNotification: Notification;
        SalesServiceOrderSearchLimitLbl: Label 'This field limits the search to Sales/Service Orders only.';
}