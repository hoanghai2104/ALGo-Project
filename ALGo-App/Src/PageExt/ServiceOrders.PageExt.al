pageextension 50142 "Service Order Ext." extends "Service Orders"
{
    layout
    {
        addlast(Control1)
        {
            field("To Invoice"; Rec."To Invoice")
            {
                ApplicationArea = All;
            }
        }
    }
}