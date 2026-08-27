reportextension 50107 ServiceContractQuote extends "Service Contract Quote"
{
    dataset
    {
        // Add changes to dataitems and columns here
        add("Service Contract Header")
        {
            column(Nom_du_Proprietaire; "Service Contract Header".GetNomduProprietaire()) { }
            column(Reference_Supp_; "Reference Supp.") { }

        }

        add("Service Contract Line")
        {
            column(Description_Supp_ServiceLine; "Description Supp.") { }
        }

    }

}