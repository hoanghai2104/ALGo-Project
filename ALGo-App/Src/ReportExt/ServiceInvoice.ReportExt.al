reportextension 50105 ServiceInvoice extends "Service - Invoice"
{
    dataset
    {
        // Add changes to dataitems and columns here
        add("Service Invoice Header")
        {
            column(Nom_du_Proprietaire; "Service Invoice Header".GetNomduProprietaire()) { }
            column(Reference_Supp_; "Reference Supp.") { }

        }

        add("Service Invoice Line")
        {
            column(Description_Supp_; "Description Supp.") { }
        }
    }

}