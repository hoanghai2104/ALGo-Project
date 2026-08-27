pageextension 50117 ServiceorderCard extends "Service Order"
{
    layout
    {

        // Add changes to page layout here
        addlast(General)
        {
            field("Sales Order Reference"; Rec."Sales Order Reference")
            {
                ApplicationArea = all;
                Editable = false;
                // Enabled = false;
            }
            // field(TechnitianName; Rec.TechnitianName)
            // {
            //     ApplicationArea = all;
            //     // Editable = false;
            //     Caption = 'Nom du technicien';
            //     Lookup = true;
            //     LookupPageId = "Resource List";

            //     trigger OnAfterLookup(Selected: RecordRef)
            //     var
            //         ResourceRec: Record Resource;
            //     begin
            //         ResourceRec := Selected;
            //         Rec.TechnitianID := ResourceRec."No.";
            //     end;

            // }

            field("Nom du technicien"; Rec."Nom du technicien")
            {
                ApplicationArea = all;
                Caption = 'Nom du technicien';
            }

            group("Nom du Proprietaire Group")
            {
                Caption = 'Nom du Propriétaire';
                field("Nom du Proprietaire"; NomDuProprietaire)
                {
                    ApplicationArea = all;
                    Importance = Additional;
                    MultiLine = true;
                    ShowCaption = false;
                    trigger OnValidate()
                    begin
                        Rec.SetNomduProprietaire(NomDuProprietaire);
                        SyncNomDuProprietaireToSalesOrder();
                    end;
                }
            }
            field("N° de l’intervention"; Rec."N° de l’intervention")
            {
                ApplicationArea = all;
            }
            field("Reference Supp."; Rec."Reference Supp.")
            {
                Caption = 'Référence Supp.';
                ApplicationArea = all;
            }
            field("To Invoice"; Rec."To Invoice")
            {
                ApplicationArea = All;
                Editable = false;
            }
        }

    }

    actions
    {
        // Add changes to page actions here
    }

    trigger OnAfterGetRecord()
    begin
        NomDuProprietaire := Rec.GetNomduProprietaire();
    end;


    procedure SyncNomDuProprietaireToSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        NomProprietaireSalesOrder: Text;
    begin
        if NomDuProprietaire = '' then
            exit;

        if (rec."Sales Order Reference" <> '') then begin
            if SalesHeader.Get(SalesHeader."Document Type"::Order, rec."Sales Order Reference") then begin
                NomProprietaireSalesOrder := NomDuProprietaire;
                SalesHeader.SetNomduProprietaire(NomProprietaireSalesOrder);
            end;
        end
    end;

    var
        NomDuProprietaire: Text;
}