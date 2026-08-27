tableextension 50108 ServiceHeader extends "Service Header"
{
    AllowInCustomizations = AsReadOnly;

    fields
    {
        // Add changes to table fields here
        field(50100; "Sales Order Reference"; Code[20])
        {
            TableRelation = "Sales Header"."No." where("Document Type" = const(Order));
        }
        modify(Status)
        {
            trigger OnAfterValidate()
            var
                salesHeader: Record "Sales Header";
            begin
                if salesHeader.Get(salesHeader."Document Type"::Order, Rec."Sales Order Reference") then begin
                    salesHeader."Statut commande" := Rec.Status;
                    salesHeader.Modify();
                end;

            end;
        }
        field(50101; TechnitianName; Code[20])
        {
            Caption = 'Nom du technicien unused';
            TableRelation = Resource.Name;
            ValidateTableRelation = false;
            obsoleteState = Pending;
            ObsoleteReason = 'replaced by Nom du technicien';
            trigger OnValidate()
            var
                salesHeader: Record "Sales Header";
            begin
                if (rec."Sales Order Reference" <> '') then begin

                    if salesHeader.Get(salesHeader."Document Type"::Order, rec."Sales Order Reference") then begin
                        salesHeader.TechnitianName := rec.TechnitianName;
                        salesHeader.Modify();
                    end;
                end;
            end;
        }
        field(50102; FunctionalLocationID; GUID)
        {

            Description = 'Poste technique de l’ordre de travail';
            Caption = 'Poste technique';
            FieldClass = Normal;
            ObsoleteState = Removed;
            ObsoleteReason = 'Remove';
            trigger OnValidate()
            var
                ServiceHeaderRef: RecordRef;
                ShipToCode: Code[20];
            begin
                // ServiceHeaderRef := Rec;
                // shiptoAddressCodeunit.RetriveFunctionalLocationCode(ServiceHeaderRef, ShipToCode);
                // Rec.Validate("Ship-to Code", ShipToCode);
            end;

        }
        field(50103; "Nom du Proprietaire"; Blob)
        {
            Caption = 'Nom du Propriétaire';


        }

        field(50104; "N° de l’intervention"; Text[100])
        {

        }
        field(50105; "Reference Supp."; Text[800])
        {
            Caption = 'Référence Supp.';
        }
        field(50106; "TechnitianID"; Code[20])
        {
            Caption = 'TechnitianID_unused';
            TableRelation = Resource."No.";
            ValidateTableRelation = false;
            DataClassification = SystemMetadata;
            obsoleteState = Pending;
            ObsoleteReason = 'replaced by Nom du technicien';
        }

        field(50107; "Nom du technicien"; code[100])
        {
            Caption = 'Nom du technicien';
            TableRelation = Resource.Name;
            ValidateTableRelation = false;
            trigger OnValidate()
            var
                salesHeader: Record "Sales Header";
            begin
                if (rec."Sales Order Reference" <> '') then begin

                    if salesHeader.Get(salesHeader."Document Type"::Order, rec."Sales Order Reference") then begin
                        salesHeader."Nom du technicien" := rec."Nom du technicien";
                        salesHeader.Modify();
                    end;
                end;
            end;
        }
        field(50108; "To Invoice"; Boolean)
        {
            Caption = 'To Invoice';
        }

    }

    keys
    {
        // Add changes to keys here
    }

    fieldgroups
    {
        // Add changes to field groups here
    }
    trigger OnInsert()
    begin
        if rec."Document Type" in ["Document Type"::Order, "Document Type"::"Credit Memo", "Document Type"::Quote, "Document Type"::Invoice] then begin
            rec."Assigned User ID" := Format(UserId);
            Rec.Validate("Assigned User ID");
        end;
    end;

    procedure SetNomduProprietaire(NewNomduProprietaire: Text)
    var
        OutStream: OutStream;
    begin
        Clear("Nom du Proprietaire");
        "Nom du Proprietaire".CreateOutStream(OutStream, TEXTENCODING::UTF8);
        OutStream.WriteText(NewNomduProprietaire);
        rec.Modify();
    end;

    procedure GetNomduProprietaire() NomduProprietaire: Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStream: InStream;
    begin
        CalcFields("Nom du Proprietaire");
        "Nom du Proprietaire".CreateInStream(InStream, TEXTENCODING::UTF8);
        exit(TypeHelper.TryReadAsTextWithSepAndFieldErrMsg(InStream, TypeHelper.LFSeparator(), FieldName("Nom du Proprietaire")));
    end;


    var
        shiptoAddressCodeunit: Codeunit "ShipToAddress";
    //in
}