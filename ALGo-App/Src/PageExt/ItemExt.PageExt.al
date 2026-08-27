pageextension 50101 "ItemExt" extends "Item Card"
{
    layout
    {
        // Add changes to page layout here
        addlast("Prices & Sales")
        {

            field("Code RPLP"; Rec."Code RPLP")
            {
                ApplicationArea = all;
                Lookup = true;
                LookupPageId = RplpParametrageList;
            }

        }
    }

    actions
    {
        // Add changes to page actions here
    }

}