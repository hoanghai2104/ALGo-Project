pageextension 50144 "PostedSalesShpt.Subform" extends "Posted Sales Shpt. Subform"
{
    layout
    {
        // Add changes to page layout here
        addafter("Unit of Measure Code")
        {
            field("Total Quantity"; Rec."Total Quantity")
            {
                ApplicationArea = All;
            }
            field("ELCA Qty. Shipped"; Rec."ELCA Qty. Shipped")
            {
                ApplicationArea = all;
                Caption = 'Qtité expédiée';
            }
            field("ELCA Qty. to Ship"; Rec."ELCA Qty. to Ship")
            {
                ApplicationArea = all;
                Caption = 'Qtité à expédier';

            }
        }
    }

}