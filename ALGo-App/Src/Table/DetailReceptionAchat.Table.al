table 50109 "DetailReceptionAchat"
{
    Caption = 'Détail Réception Achat PM';
    DataClassification = ToBeClassified;
    AllowInCustomizations = AsReadOnly;



    fields
    {
        field(1; EntryNo; Integer)
        {
            Caption = 'No. d’entrée';
            DataClassification = ToBeClassified;
            AutoIncrement = true;
        }
        field(2; "ItemNo"; Code[20])
        {
            Caption = 'No. article';
            DataClassification = ToBeClassified;
        }
        field(3; "Quantity"; Decimal)
        {
            Caption = 'Quantité';
            DataClassification = ToBeClassified;
        }
        field(4; "SalesOrderNo"; Code[20])
        {
            Caption = 'N°. commande de vente';
            DataClassification = ToBeClassified;
            ObsoleteState = Pending;
            ObsoleteReason = 'Removed in favor of DocumentNo and DocumentType fields.';
        }
        field(5; "InterventionNo"; Code[20])
        {
            Caption = 'N° de l’intervention';
            DataClassification = ToBeClassified;
            ObsoleteState = Pending;
            ObsoleteReason = 'removed in favor of "No de intervention" field.';
        }
        field(6; "TechnicianName"; Text[100])
        {
            Caption = 'Nom du technicien';
            DataClassification = ToBeClassified;
        }
        field(7; "OrderGiverName"; Text[100])
        {
            Caption = 'Nom du donneur d’ordre';
            DataClassification = ToBeClassified;
        }

        field(8; "TenantName"; Text[100])
        {
            Caption = 'Nom du Locataire';
            DataClassification = ToBeClassified;
        }
        field(9; DocumentNo; Code[20])
        {
            Caption = 'No. document';
            DataClassification = ToBeClassified;
        }
        field(10; DocumentType; Enum "Item Ledger Document Type")
        {
            Caption = 'Type de document';
            DataClassification = ToBeClassified;
        }
        field(11; "Reference Libre"; Text[100])
        {
            Caption = 'Référence Libre';
            DataClassification = ToBeClassified;
        }
        field(12; "No de intervention"; Text[100])
        {
            Caption = 'N° de l’intervention';
        }
        field(13; "Phma document order type"; Text[100])
        {

        }
        field(14; "Posted Purch Receipt No"; Code[20])
        {
            Caption = 'No. réception achat postée';
            DataClassification = ToBeClassified;
        }

        field(15; "Assigned User ID"; Code[50])
        {
            Caption = 'Code utilisateur affecté';
        }
        field(16; "Purchase Order No"; Code[20])
        {
            Caption = 'No. commande achat';
            FieldClass = FlowField;
            CalcFormula = lookup("Purch. Rcpt. Header"."Order No." where("No." = field("Posted Purch Receipt No")));
            Editable = false;
        }
        field(17; VendorName; Text[100])
        {
            Caption = 'Nom du fournisseur';
            FieldClass = FlowField;
            CalcFormula = lookup("Purch. Rcpt. Header"."Buy-from Vendor Name" where("No." = field("Posted Purch Receipt No")));
            Editable = false;
        }
        field(18; VendorNo; Code[20])
        {
            Caption = 'No. fournisseur';
            FieldClass = FlowField;
            CalcFormula = lookup("Purch. Rcpt. Header"."Buy-from Vendor No." where("No." = field("Posted Purch Receipt No")));
            Editable = false;
        }

        field(19; VendorSearchName; Text[100])
        {
            Caption = 'Nom de recherche du fournisseur';
            FieldClass = FlowField;
            CalcFormula = lookup(Vendor."Search Name" where("No." = field(VendorNo)));
            Editable = false;
        }
        field(20; "Posting Date"; Date)
        {
            Caption = 'Date de comptabilisation';
            FieldClass = FlowField;
            CalcFormula = lookup("Purch. Rcpt. Header"."Posting Date" where("No." = field("Posted Purch Receipt No")));
            Editable = false;
        }
        field(21; CustomerSearchName; Text[100])
        {
            Caption = 'Nom de recherche du client';
        }
        field(22; "Désignation de l'article"; Text[100])
        {
            Caption = 'Désignation de l’article';
            FieldClass = FlowField;
            CalcFormula = lookup(Item.Description where("No." = field(ItemNo)));
            Editable = false;
        }
        field(23; Instructions; Text[100])
        {
            Caption = 'Instructions';
            DataClassification = ToBeClassified;
        }
    }

    keys
    {
        key(PK; EntryNo)
        {
            Clustered = true;
        }
    }
}
