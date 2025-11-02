--ex 12
--Afiseaza, pentru fiecare comanda livrata, ID-ul comenzii, numele clientului cu litere mici,
--tipul platii scris cu litere mari si numele firmei de transport, alaturi de lungimea numelui firmei.
-- a) subcerere sincronizata care implica >=3 tabele (COMANDA, CLIENT, MOD_PLATA, TRANSPORT)
-- e) functii pe siruri: LOWER, UPPER, LENGTH
SELECT 
    c_filtrate.id_comanda,
    LOWER(c_filtrate.nume_client) AS nume_client,
    UPPER(c_filtrate.tip_plata) AS tip_plata,
    c_filtrate.firma_transport,
    LENGTH(c_filtrate.firma_transport) AS lungime_nume_transport
FROM (
    SELECT co.id_comanda, cl.nume AS nume_client, mp.tip_plata, t.firma AS firma_transport
    FROM COMANDA co
    JOIN CLIENT cl ON co.id_client = cl.id_client
    JOIN MOD_PLATA mp ON co.id_modplata = mp.id_modplata
    JOIN TRANSPORT t ON co.id_transport = t.id_transport
    WHERE co.status_comanda = 'livrata'
) c_filtrate;

--Afiseaza numele clientilor care s-au inregistrat cu mai mult de 12 luni in urma,
--data de inregistrare in formatul DD-MON-YYYY si numarul de luni care au trecut
--de la acel moment.
--b) subcereri nesincronizate în clauza FROM
--e) functii pe date calendaristice: MONTHS_BETWEEN, TO_CHAR
SELECT c.nume, 
       TO_CHAR(c.data_inregistrare, 'DD-MON-YYYY') AS data_inregistrare,
       TRUNC(MONTHS_BETWEEN(SYSDATE, c.data_inregistrare)) AS luni_de_la_inregistrare
FROM (SELECT id_client, nume, data_inregistrare FROM CLIENT) c
JOIN COMANDA co ON c.id_client = co.id_client
WHERE MONTHS_BETWEEN(SYSDATE, c.data_inregistrare) > 12;

--Afiseaza producatorii care au cel putin un produs in stoc, dar doar daca valoarea
--totala a produselor lor aflate in stoc este mai mare decat media valorii totale a
--stocurilor tuturor producatorilor. (afiseaza ID producator, nume producator, valoare totala stoc)
-- c) grupari date (id_producator, nume), functii grup (SUM,AVG), subcerere nesincronizata (HAVING)
SELECT 
    p.id_producator,
    p.nume,
    SUM(s.cantitate_disp * s.pret) AS valoare_totala_stoc
FROM PRODUCATOR p
JOIN STOC s ON p.id_producator = s.id_producator
GROUP BY p.id_producator, p.nume
HAVING SUM(s.cantitate_disp * s.pret) > (
    SELECT AVG(valoare_stoc)
    FROM (
        SELECT SUM(cantitate_disp * pret) AS valoare_stoc
        FROM STOC
        GROUP BY id_producator
    )
);

--Afiseaza numele tuturor produselor, numele producatorului asociat fiecarui produs,
--reducerea produsului (daca nu exista sau este NULL, afiseaza 0) si starea stocului
--fiecarui produs ('Epuizat' daca este stoc 0, 'Mic' daca este 1, altfel 'Disponibil').
--Rezultatul ordoneaza-l alfabetic, dupa numele producatorului, apoi al produsului.
-- d) DECODE, NVL (in aceeasi cerere), ORDER BY
SELECT 
    p.nume_produs,
    pr.nume AS nume_producator,
    NVL(r.procentaj, 0) AS reducere_produs,
    DECODE(s.cantitate_disp, 
           0, 'Stoc epuizat', 
           1, 'Stoc mic', 
           'Disponibil') AS stare_stoc
FROM PRODUS p
JOIN STOC s ON p.id_produs = s.id_produs
JOIN PRODUCATOR pr ON s.id_producator = pr.id_producator
LEFT JOIN REDUCERE r ON s.id_produs = r.id_produs AND s.id_producator = r.id_producator
ORDER BY pr.nume, p.nume_produs;

--Afiseaza lista de produse cu reducerile lor si clasificarea acestora
--in functie de marimea reducerii (=0 'Fara reducere', intre 1 si 10
--'Reducere mica', >10 'Reducere mare')
-- f) WITH
-- e) CASE
WITH reduceri_produs AS (
    SELECT 
        p.id_produs,
        p.nume_produs,
        r.procentaj
    FROM 
        PRODUS p
    LEFT JOIN 
        REDUCERE r 
    ON 
        p.id_produs = r.id_produs
)
SELECT 
    rp.nume_produs,
    NVL(rp.procentaj, 0) AS reducere_produs,
    CASE
        WHEN NVL(rp.procentaj, 0) = 0 THEN 'Fara reducere'
        WHEN NVL(rp.procentaj, 0) BETWEEN 1 AND 10 THEN 'Reducere mica'
        WHEN NVL(rp.procentaj, 0) > 10 THEN 'Reducere mare'
    END AS categorie_reducere
FROM 
    reduceri_produs rp
ORDER BY 
    rp.nume_produs;


--ex 13
--Sa se actualizeze prețurile produselor care au recenzii cu rating <=2
--astfel incat pretul lor sa scada cu 10%
UPDATE STOC s
SET pret = pret * 0.9
WHERE id_produs IN (
    SELECT id_produs
    FROM RECENZIE
    WHERE rating <= 2
);

--Sa se stearga contactele clientilor care au comandat produsul
--'pix albastru' iar pretul total al comenzii este mai mic de 50
DELETE FROM CONTACTE_CLIENT
WHERE id_client IN (
    SELECT c.id_client
    FROM COMANDA c
    JOIN COMANDA_PRODUS cp ON c.id_comanda = cp.id_comanda
    JOIN PRODUS p ON cp.id_produs = p.id_produs
    WHERE p.nume_produs = 'pix albastru'
    AND c.id_comanda IN (
        -- Subcerere pentru a verifica comenzile cu valoare totală < 50
        SELECT cp2.id_comanda
        FROM COMANDA_PRODUS cp2
        GROUP BY cp2.id_comanda
        HAVING SUM(cp2.pret * cp2.cantitate) < 50
    )
);

--Actualizeaza stocul general al produselor care exista in comanda unui client care are
--un contact tip 'telefon', iar cel putin un produs din comanda se afla in categoria 'papetarie'
--astfel incat noul stoc al produselor sa fie egal cu media tuturor stocurilor.
UPDATE STOC s
SET cantitate_disp = s.cantitate_disp + (
    SELECT AVG(s2.cantitate_disp) 
    FROM STOC s2
)
WHERE s.id_produs IN (
    SELECT DISTINCT cp.id_produs
    FROM COMANDA c
    JOIN COMANDA_PRODUS cp ON c.id_comanda = cp.id_comanda
    JOIN CLIENT cl ON c.id_client = cl.id_client
    JOIN CONTACTE_CLIENT cc ON cl.id_client = cc.id_client
    JOIN PRODUS p ON cp.id_produs = p.id_produs
    WHERE cc.tip_contact = 'telefon'
    AND EXISTS (
        SELECT 1 
        FROM COMANDA_PRODUS cp2
        JOIN PRODUS p2 ON cp2.id_produs = p2.id_produs
        WHERE cp2.id_comanda = c.id_comanda
        AND p2.categorie = 'papetarie'
    )
);

commit;

--ex 14
--Crearea vizualizării complexe: Afișează informații detaliate despre comenzile plasate de clienți.
CREATE VIEW Vizualizare_Comenzi_Complete AS
SELECT
    C.id_comanda,
    Cl.nume AS nume_client,
    P.nume_produs,
    CP.cantitate,
    CP.pret,
    Pr.nume AS producator,
    T.firma AS firma_transport,
    T.timp,
    T.cost AS cost_transport,
    MP.tip_plata
FROM COMANDA C
JOIN CLIENT Cl ON C.id_client = Cl.id_client
JOIN COMANDA_PRODUS CP ON C.id_comanda = CP.id_comanda
JOIN PRODUS P ON CP.id_produs = P.id_produs
JOIN STOC S ON P.id_produs = S.id_produs
JOIN PRODUCATOR Pr ON S.id_producator = Pr.id_producator
JOIN TRANSPORT T ON C.id_transport = T.id_transport
JOIN MOD_PLATA MP ON C.id_modplata = MP.id_modplata;

--Exemplu de operație LMD permisă: Obține informații despre toate comenzile plătite cu card. Este o operație permisă deoarece doar interoghează datele dintr-o vizualizare definită printr-un SELECT.
SELECT *
FROM Vizualizare_Comenzi_Complete
WHERE tip_plata = 'card';


--Exemplu de operație LMD nepermisă: Încercarea de a insera sau actualiza datele într-o vizualizare ce conține joinuri multiple, coloane din tabele diferite sau chei compuse.
INSERT INTO Vizualizare_Comenzi_Complete
(id_comanda, nume_client, nume_produs, cantitate, pret, producator, firma_transport, timp, cost_transport, tip_plata)
VALUES (101, 'Popescu Andrei', 'Laptop', 1, 3500, 'HP', 'FanCourier', 2, 20, 'CARD');

--ex 15
--a) Afișează toate comenzile, inclusiv cele care nu au produse asociate, transport sau metodă de plată, împreună cu informații despre client, produs, transport și metodă de plată, dacă există. (OUTER JOIN)
SELECT
    C.id_comanda,
    Cl.nume AS nume_client,
    P.nume_produs,
    T.firma AS firma_transport,
    MP.tip_plata
FROM COMANDA C
LEFT JOIN CLIENT Cl ON C.id_client = Cl.id_client
LEFT JOIN COMANDA_PRODUS CP ON C.id_comanda = CP.id_comanda
LEFT JOIN PRODUS P ON CP.id_produs = P.id_produs
LEFT JOIN TRANSPORT T ON C.id_transport = T.id_transport
LEFT JOIN MOD_PLATA MP ON C.id_modplata = MP.id_modplata;

--b) Afișează clienții care au dat comenzi pentru toate produsele din categoria ‘arta’ (DIVSION)
SELECT C.id_client
FROM COMANDA C
JOIN COMANDA_PRODUS CP ON C.id_comanda = CP.id_comanda
JOIN PRODUS P ON CP.id_produs = P.id_produs
WHERE P.categorie = 'arta'
GROUP BY C.id_client
HAVING COUNT(DISTINCT P.id_produs) = (
    SELECT COUNT(DISTINCT id_produs)
    FROM PRODUS
    WHERE categorie = 'arta'
);

--Afișează top 3 clienți care au cheltuit cel mai mult în total pe comenzi (ANALIZA TOP-N)
SELECT 
    C.id_client,
    Cl.nume,
    SUM(CP.pret * CP.cantitate) AS total_cheltuit
FROM COMANDA C
JOIN CLIENT Cl ON C.id_client = Cl.id_client
JOIN COMANDA_PRODUS CP ON C.id_comanda = CP.id_comanda
GROUP BY C.id_client, Cl.nume
ORDER BY total_cheltuit DESC
FETCH FIRST 3 ROWS ONLY;

