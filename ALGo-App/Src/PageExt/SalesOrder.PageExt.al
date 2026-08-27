pageextension 50106 SalesOrder extends "Sales Order"
{
    layout
    {
        // Add changes to page layout here
        addafter("Requested Delivery Date")
        {
            field("Reference Supp."; Rec."Reference Supp.")
            {
                ApplicationArea = All;
                Caption = 'Référence Supp.';
            }

        }
        addlast(General)
        {
            field("Type commande service"; Rec."Type commande service")
            {
                ApplicationArea = all;
            }
            field("Statut commande"; Rec."Statut commande")
            {
                ApplicationArea = all;
                trigger OnValidate()
                begin
                    if Rec."Statut commande" = Rec."Statut commande"::" " then begin
                        Rec.FieldError("Statut commande", 'Invalid');
                    end;
                end;
            }
            field("N° de l’intervention"; Rec."N° de l’intervention")
            {
                ApplicationArea = all;
            }
            // field(TechnitianName; Rec.TechnitianName)
            // {
            //     Caption = 'Nom du technicien';
            //     ApplicationArea = all;
            // }
            field("Nom du technicien"; Rec."Nom du technicien")
            {
                Caption = 'Nom du technicien';
                ApplicationArea = all;
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
                    end;
                }
            }
        }
    }

    actions
    {
        // Add changes to page actions here
        // addlast(Category_Process)
        addafter("P&osting")
        {
            action("Calculate RPLP")
            {
                ApplicationArea = all;
                Image = Calculate;

                trigger OnAction()
                var
                    CalculateRPLP: Codeunit CalculateRPLP;
                begin
                    CalculateRPLP.CalculateRplp(Rec);
                end;
            }
            action("Create Service")
            {
                ApplicationArea = all;
                Image = ServiceAgreement;
                trigger OnAction()
                begin
                    ServiceOrderManagement.createServiceOrder(Rec);
                end;
            }
        }

        addlast(Category_Process)
        {
            actionref(Promoted_CalculateRPLP; "Calculate RPLP") { }
            actionref(Promoted_Create_service; "Create Service") { }
        }
    }
    trigger OnAfterGetRecord()
    begin
        NomDuProprietaire := Rec.GetNomduProprietaire();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Statut commande" := Rec."Statut commande"::" ";

    end;

    var
        ServiceOrderManagement: Codeunit ServiceOrderManagement;
        NomDuProprietaire: Text;
}