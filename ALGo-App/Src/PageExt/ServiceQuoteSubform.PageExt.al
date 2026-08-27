pageextension 50136 ServiceQuoteSubform extends "Service Quote Subform"
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