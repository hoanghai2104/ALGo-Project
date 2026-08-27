reportextension 50106 ServiceCreditMemo extends "Service - Credit Memo"
{
    dataset
    {
        // Add changes to dataitems and columns here
        add("Service Cr.Memo Header")
        {
            column(Nom_du_Proprietaire; "Service Cr.Memo Header".GetNomduProprietaire()) { }
            column(Reference_Supp_; "Reference Supp.") { }

        }

        add("Service Cr.Memo Line")
        {
            column(Description_Supp_; "Description Supp.") { }
        }
    }

}