reportextension 50103 ServiceQuote extends "Service Quote"
{
    dataset
    {
        // Add changes to dataitems and columns here
        add("Service Header")
        {
            column(Nom_du_Proprietaire; "Service Header".GetNomduProprietaire()) { }
            column(Assigned_User_ID; "Assigned User ID") { }
            column(Reference_Supp_; "Reference Supp.") { }

        }

        add("Service Line")
        {
            column(Description_Supp_ServiceLine; "Description Supp.") { }
        }
        add("Service Item Line")
        {
            column(Description_Supp_ServiceItemLine; "Description Supp.") { }
        }
    }

}