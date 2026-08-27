pageextension 50116 SalesAndReceivable extends "Sales & Receivables Setup"
{
    layout
    {
        // Add changes to page layout here
        addlast("Number Series")
        {
            field("Soumission  Nos"; Rec."Soumission Nos")
            {
                ApplicationArea = all;
                TableRelation = "No. Series";
                ToolTip = 'Specifies the code for the number series that will be used to assign numbers to sales orders.';
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }

}