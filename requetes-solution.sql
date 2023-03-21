-- -----------------------------------------------------------------------------
-- *****************************************************************************
-- -----------------------------------------------------------------------------
-- A) Requêtes assez simples ("faciles")
-- -----------------------------------------------------------------------------
-- *****************************************************************************
-- -----------------------------------------------------------------------------

-- A1) Retourner l'identifiant et le sku des produits qui ne sont pas en stock
SELECT  prd_id,
        prd_sku
    FROM product 
    WHERE prd_stock = 0;

-- A2) Retourner le nom en français (il y avait une ambiguité dans le 
-- devis initial) et sku des produits dont le stock > 50
SELECT  pdd_name,
        prd_sku
    FROM product 
        JOIN product_detail ON pdd_prd_id_fk = prd_id
    WHERE prd_stock > 50 AND pdd_lang='fr'

-- A3) Retourner les noms des catégories en français
SELECT cat_name_fr FROM category;

-- A4) Retourner les types de produits en français dans la catégorie 
-- "Huiles d'olive extra vierges"
SELECT typ_name_fr FROM type WHERE typ_cat_id_fk=1;
    -- Sachant qu'il s'agit de la catégorie 1.

-- A5) Retourner le nombre de produits par catégorie (le devis n'est pas
-- précis ici, alors on fait le plus simple ;-))
SELECT  prd_cat_id_fk,
        COUNT(prd_id) AS nombreProduits
    FROM product 
    GROUP BY prd_cat_id_fk;

-- A6) Retourner le nombre de produits par type (idem comme pour A5)
SELECT  prd_typ_id_fk,
        COUNT(prd_id) AS nombreProduits
    FROM product 
    GROUP BY prd_typ_id_fk;

-- A7) Retourner l'information complète des produits en français 
-- (info de base et détail) pour les produits de type "Accessoires"
SELECT  * 
    FROM product 
        JOIN product_detail ON pdd_prd_id_fk=prd_id
    WHERE prd_type_id_fk=17
    -- Sachant qu'il s'agit du type de produit 17.

-- A8) Retourner le chiffre d'affaire total (d'après les commandes)
SELECT SUM(ord_total) AS chiffreAffaire FROM `order`;
    -- Attention ici : le mot 'order' est un mot clé du langage SQL
    -- et on ne peut l'utiliser dans les noms de structures sans devoir
    -- l'entourer des délimiteurs `` au moment de le référencer.

-- A9) Retourner la date et le numéro de la commande la plus ancienne
SELECT  ord_number, 
        ord_date
    FROM `order` 
    ORDER BY ord_date ASC 
    LIMIT 1;
    -- Cette question est mal formulée : il peut y avoir plus d'une commande
    -- à la même date ... ;-(

-- A10) Retourner la date et le numéro de la commande la plus récente 
SELECT  ord_number, 
        ord_date
    FROM `order` 
    ORDER BY ord_date DESC 
    LIMIT 1;
    -- Même commentaire que celui laissé à A10

-- A11) Retourner le nombre de clients par année
SELECT  YEAR(cli_date) AS annee, 
        COUNT(cli_id) AS nbClients 
    FROM client 
    GROUP BY annee;

-- A12) Retourner le nom et prénom du client, le numéro de commande et 
-- le sous-total des commandes placées dans les 6 derniers mois
SELECT  cli_lastname,
        cli_firstname,
        ord_number,
        ord_total
    FROM client 
        JOIN `order` ON cli_id = ord_cli_id_fk
    WHERE ord_date > DATE_SUB(CURDATE(), INTERVAL 6 MONTH);

-- -----------------------------------------------------------------------------
-- *****************************************************************************
-- -----------------------------------------------------------------------------
-- B) Requêtes nettement plus complexes ("difficiles") 
-- -----------------------------------------------------------------------------
-- Des captures d'écrans des jeux d'enregistrements résultants sont inclus 
-- dans le dossier "résultats-escomptés"
-- -----------------------------------------------------------------------------
-- Je tiendrais compte uniquement de vos 8 meilleures réponses sur les 
-- 14 requêtes de cette section (B)
-- -----------------------------------------------------------------------------
-- *****************************************************************************
-- -----------------------------------------------------------------------------

-- B1) Retourner l'identifiant, le nom en anglais, et le prix ordinaire 
-- du produit le plus cher du catalogue
-- Suggestion : ORDER BY et LIMIT
SELECT  prd_id, 
        pdd_name, 
        prd_price
	FROM product 
        JOIN product_detail ON pdd_prd_id_fk=prd_id
    WHERE pdd_lang='en' 
 	ORDER BY prd_price DESC
    LIMIT 1;

-- B2) Retourner les noms de catégorie en français et le prix du produit 
-- le plus cher dans chacune des catégories de produits disponibles.
SELECT  cat_name_fr, 
        MAX(prd_price) AS prixLePlusCher
	FROM product 
        JOIN category ON prd_cat_id_fk=cat_id
 	GROUP BY cat_name_fr;

-- B3) Retourner l'identifiant, nom en français, petite image, prix, 
-- prix de solde, et quantité en stock de tous les produits actifs de 
-- type 'vinaigres balsamiques'
SELECT  prd_id, 
        pdd_name, 
        prd_img_small, 
        prd_price, 
        prd_saleprice, 
        prd_stock 
	FROM product 
        JOIN product_detail ON pdd_prd_id_fk = prd_id
    WHERE prd_active=1 AND pdd_lang='fr' AND prd_typ_id_fk=9;

-- B4) Retourner le id, le nom en français, et la petite image de produit, 
-- ainsi que la quantité, des produits dans le panier d'achat dont le id est 822310
SELECT  prd_id, 
        pdd_name, 
        prd_img_small, 
        crd_quantity 
    FROM product 
        JOIN product_detail ON pdd_prd_id_fk=prd_id
    	JOIN cart_detail ON crd_prd_id_fk=prd_id
    WHERE crd_crt_id_fk=822310 AND pdd_lang='fr';

-- B5) Même chose, mais cette fois-ci ajoutez le prix du produit 
-- (qui pourrait être en solde !)
-- Suggestion : COALESCE ou LEAST/IFNULL
SELECT  prd_id, 
        pdd_name, 
        prd_img_small, 
        crd_quantity, 
        COALESCE(prd_saleprice, prd_price) AS prixProduit 
    FROM product 
        JOIN product_detail ON pdd_prd_id_fk=prd_id
    	JOIN cart_detail ON crd_prd_id_fk=prd_id
    WHERE crd_crt_id_fk=822310 AND pdd_lang='fr';

-- B6) Retourner l'identifiant du panier et le sous-total des produits 
-- (avant taxes et frais de livraison) de tous les paniers d'achats non-vides 
-- (ignorez les "cours", seulement les "produits") triés par ordre descendant 
-- de sous-total
-- Suggestion : COALESCE
SELECT  crd_crt_id_fk, 
        SUM(COALESCE(prd_saleprice, prd_price)*crd_quantity) AS sousTotalPanier
	FROM cart_detail 
        JOIN product ON crd_prd_id_fk = prd_id
    GROUP BY crd_crt_id_fk
    ORDER BY sousTotalPanier DESC;

-- B7) Retourner les origines distinctes des produits, en français
-- Suggestion : SELECT DISTINCT
SELECT DISTINCT pdd_origin
	FROM product_detail
    WHERE pdd_lang='fr';

-- B8) Retourner dans une seule chaîne de caractères toutes les origines 
-- distinctes de produits en français (séparées par le symbole |)
-- Suggestion : GROUP_CONCAT
SELECT GROUP_CONCAT(DISTINCT pdd_origin SEPARATOR '|') as originesFr 
	FROM product_detail
    WHERE pdd_lang='fr';

-- B9) Retourner le nombre de paniers vides
-- Suggestion : type de jointure ???
SELECT COUNT(crt_id) AS nombrePaniersVides
	FROM cart 
        LEFT JOIN cart_detail ON crd_crt_id_fk=crt_id
    WHERE crd_id IS NULL;

-- B10) Retourner les numéros de série distincts (crt_serial) des paniers 
-- qui ne sont pas vides ordonnés par identifiant de panier
-- Suggestion : type de jointure ???
SELECT DISTINCT crt_serial
	FROM cart 
        LEFT JOIN cart_detail ON crd_crt_id_fk=crt_id
    WHERE crd_id IS NOT NULL
    ORDER BY crt_id;

-- B11) Retourner le nombre de panier distincts non-vides
-- Suggestion : type de jointure ???
SELECT COUNT(DISTINCT crt_serial) AS nombrePaniersNonVides
	FROM cart 
        LEFT JOIN cart_detail ON crd_crt_id_fk=crt_id
    WHERE crd_id IS NOT NULL;

-- B12) Retourner l'identifiant, le SKU, et le nombre de fois commandé, 
-- des 10 produits les plus souvents commandés, ordonné par meilleur vendeur.
SELECT  prd_id, 
        prd_sku, 
        COUNT(`odd_prd_id_fk`) AS nombreCommande
    FROM product 
        JOIN order_detail ON odd_prd_id_fk=prd_id
    GROUP BY prd_id
    ORDER BY nombreCommande DESC
    LIMIT 10;

-- B13) Même question, mais au lieu du nombre de fois commandé, on 
-- demande le nombre d'articles commandés
SELECT  prd_id, 
        prd_sku, 
        SUM(`odd_quantity`) AS quantiteCommandee
    FROM product 
        JOIN order_detail ON odd_prd_id_fk=prd_id
    GROUP BY prd_id
    ORDER BY nombreCommande DESC
    LIMIT 10;

-- B14) Supprimer les paniers vides.
-- [Difficile seulement car pas d'exemple à ce jour en classe : requiert 
-- une sous-requête, sinon assez facile] 
-- Important de faire cette requête à la toute fin quand vous avez terminé 
-- l'atelier seulement.
DELETE FROM cart 
    WHERE crt_id IN 
        (SELECT crt_id 
            FROM cart 
                LEFT JOIN cart_detail ON crd_crt_id_fk=crt_id
            WHERE crd_crt_id_fk IS NULL);

