pageextension 50134 ServiceContractSubform extends "Service Contract Subform"
{
    layout
    {
        // Add changes to page layout here
        addafter("Item No.")
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