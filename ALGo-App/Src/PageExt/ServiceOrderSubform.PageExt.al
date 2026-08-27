pageextension 50137 ServiceOrderSubform extends "Service Order Subform"
{
    layout
    {
        // Add changes to page layout here
        addafter(Description)
        {
            field("Description Supp."; Rec."Description Supp.")
            {
                ApplicationArea = all;
            }
        }
    }

    actions
    {
        // Add changes to page actions here
    }


}