--ex 10
CREATE SEQUENCE seq_client START WITH 1 INCREMENT BY 1 MINVALUE 1 MAXVALUE 999999 NOCYCLE NOCACHE;

CREATE SEQUENCE seq_comanda START WITH 1 INCREMENT BY 1 MINVALUE 1 MAXVALUE 999999 NOCYCLE NOCACHE;

CREATE SEQUENCE seq_produs START WITH 1 INCREMENT BY 1 MINVALUE 1 MAXVALUE 999999 NOCYCLE NOCACHE;

CREATE SEQUENCE seq_transport START WITH 1 INCREMENT BY 1 MINVALUE 1 MAXVALUE 999999 NOCYCLE NOCACHE;

CREATE SEQUENCE seq_modplata START WITH 1 INCREMENT BY 1 MINVALUE 1 MAXVALUE 999999 NOCYCLE NOCACHE;

CREATE SEQUENCE seq_contacte_client START WITH 1 INCREMENT BY 1 MINVALUE 1 MAXVALUE 999999 NOCYCLE NOCACHE;

CREATE SEQUENCE seq_bonusuri START WITH 1 INCREMENT BY 1 MINVALUE 1 MAXVALUE 999999 NOCYCLE NOCACHE;

CREATE SEQUENCE seq_recenzie START WITH 1 INCREMENT BY 1 MINVALUE 1 MAXVALUE 999999 NOCYCLE NOCACHE;

CREATE SEQUENCE seq_stoc START WITH 1 INCREMENT BY 1 MINVALUE 1 MAXVALUE 999999 NOCYCLE NOCACHE;

CREATE SEQUENCE seq_producator START WITH 1 INCREMENT BY 1 MINVALUE 1 MAXVALUE 999999 NOCYCLE NOCACHE;

CREATE SEQUENCE seq_reducere START WITH 1 INCREMENT BY 1 MINVALUE 1 MAXVALUE 999999 NOCYCLE NOCACHE;

--ex 11
CREATE TABLE TRANSPORT (
    id_transport NUMBER(13),
    firma VARCHAR2(100) NOT NULL,
    timp NUMBER(3) NOT NULL,
    cost NUMBER(10,2) NOT NULL,
    CONSTRAINT pk_transport PRIMARY KEY (id_transport)
);

CREATE TABLE MOD_PLATA (
    id_modplata NUMBER(13),
    tip_plata VARCHAR2(20) NOT NULL CHECK (tip_plata IN ('cash', 'card')),
    CONSTRAINT pk_mod_plata PRIMARY KEY (id_modplata)
);

CREATE TABLE CASH (
    id_modplata NUMBER(13),
    moneda VARCHAR2(20) NOT NULL,
    CONSTRAINT pk_cash PRIMARY KEY (id_modplata),
    CONSTRAINT fk_cash_mod_plata FOREIGN KEY (id_modplata) REFERENCES MOD_PLATA(id_modplata)
);

CREATE TABLE CARD (
    id_modplata NUMBER(13),
    numar_card VARCHAR2(20) NOT NULL,
    data_expirare DATE NOT NULL,
    tip_card VARCHAR2(20) NOT NULL,
    CONSTRAINT pk_card PRIMARY KEY (id_modplata),
    CONSTRAINT fk_card_mod_plata FOREIGN KEY (id_modplata) REFERENCES MOD_PLATA(id_modplata)
);

CREATE TABLE CLIENT (
    id_client NUMBER(13),
    nume VARCHAR2(50) NOT NULL,
    data_inregistrare DATE DEFAULT SYSDATE NOT NULL,
    tip_client VARCHAR2(50) DEFAULT 'persoana fizica',
    CONSTRAINT chk_tip_client CHECK (tip_client IN ('persoana fizica', 'persoana juridica')),
    CONSTRAINT pk_client PRIMARY KEY (id_client)
);

CREATE TABLE CONTACTE_CLIENT (
    id_contacteclient NUMBER(13),
    id_client NUMBER(13),
    tip_contact VARCHAR2(20) NOT NULL CHECK (tip_contact IN ('telefon', 'email', 'adresa')),
    valoare_contact VARCHAR2(100) NOT NULL,
    status_contact VARCHAR2(15) DEFAULT 'activ' CHECK (status_contact IN ('activ', 'inactiv')),
    CONSTRAINT pk_contacte PRIMARY KEY (id_contacteclient),
    CONSTRAINT fk_contact_client FOREIGN KEY (id_client) REFERENCES CLIENT(id_client)
);

CREATE TABLE BONUSURI (
    id_bonusuri NUMBER(13),
    id_client NUMBER(13),
    valoare_bonus NUMBER(10,2) NOT NULL,
    data_expirare DATE NULL,
    CONSTRAINT pk_bonusuri PRIMARY KEY (id_bonusuri),
    CONSTRAINT fk_bonus_client FOREIGN KEY (id_client) REFERENCES CLIENT(id_client)
);

CREATE TABLE COMANDA (
    id_comanda NUMBER(13),
    id_modplata NUMBER(13),
    id_transport NUMBER(13),
    id_client NUMBER(13),
    data_comanda DATE DEFAULT SYSDATE,
    status_comanda VARCHAR2(20) DEFAULT 'in proces' CHECK (status_comanda IN ('in proces', 'livrata', 'anulata')),
    CONSTRAINT pk_comanda PRIMARY KEY (id_comanda),
    CONSTRAINT fk_comanda_modplata FOREIGN KEY (id_modplata) REFERENCES MOD_PLATA(id_modplata),
    CONSTRAINT fk_comanda_transport FOREIGN KEY (id_transport) REFERENCES TRANSPORT(id_transport),
    CONSTRAINT fk_comanda_client FOREIGN KEY (id_client) REFERENCES CLIENT(id_client)
);

CREATE TABLE PRODUS (
    id_produs NUMBER(13),
    nume_produs VARCHAR2(100) NOT NULL,
    categorie VARCHAR2(50),
    CONSTRAINT pk_produs PRIMARY KEY (id_produs)
);

CREATE TABLE PRODUCATOR (
    id_producator NUMBER(13),
    nume VARCHAR2(100) NOT NULL,
    tara_origine VARCHAR2(100) NOT NULL,
    telefon VARCHAR2(20) NOT NULL,
    CONSTRAINT pk_producator PRIMARY KEY (id_producator)
);

CREATE TABLE STOC (
    id_produs NUMBER(13),
    id_producator NUMBER(13),
    cantitate_disp NUMBER(10) NOT NULL CHECK (cantitate_disp >= 0),
    pret NUMBER(10,2) NOT NULL CHECK (pret >= 0),
    minim_critic NUMBER(10) DEFAULT 3 NOT NULL CHECK (minim_critic >= 0),
    ultima_actualizare DATE DEFAULT SYSDATE NOT NULL,
    greutate NUMBER(5,2) CHECK (greutate > 0),
    expira DATE NOT NULL,
    CONSTRAINT pk_stoc PRIMARY KEY (id_produs, id_producator),
    CONSTRAINT fk_stoc_produs FOREIGN KEY (id_produs) REFERENCES PRODUS(id_produs),
    CONSTRAINT fk_stoc_producator FOREIGN KEY (id_producator) REFERENCES PRODUCATOR(id_producator)
);

CREATE TABLE REDUCERE (
    id_reducere NUMBER(13),
    id_produs NUMBER(13),
    id_producator NUMBER(13),
    procentaj NUMBER(10),
    metoda_aplicare VARCHAR2(100) CHECK (metoda_aplicare IN ('automat', 'cod promotional')),
    transferabila VARCHAR2(100) CHECK (transferabila IN ('da', 'nu')),
    CONSTRAINT pk_reducere PRIMARY KEY (id_reducere),
    CONSTRAINT fk_reducere_stoc FOREIGN KEY (id_produs, id_producator)
        REFERENCES STOC(id_produs, id_producator),
    CONSTRAINT unq_reducere_stoc UNIQUE (id_produs, id_producator)
);

CREATE TABLE RECENZIE (
    id_recenzie NUMBER(13),
    id_client NUMBER(13),
    id_produs NUMBER(13),
    id_producator NUMBER(13),
    rating NUMBER(2) CHECK (rating >= 1 AND rating <= 5),
    data_recenzie DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT pk_recenzie PRIMARY KEY (id_recenzie),
    CONSTRAINT fk_recenzie_client FOREIGN KEY (id_client) REFERENCES CLIENT(id_client),
    CONSTRAINT fk_recenzie_produs FOREIGN KEY (id_produs) REFERENCES PRODUS(id_produs),
    CONSTRAINT fk_recenzie_producator FOREIGN KEY (id_producator) REFERENCES PRODUCATOR(id_producator)
);

CREATE TABLE COMANDA_PRODUS (
    id_comanda NUMBER(13),
    id_produs NUMBER(13),
    cantitate NUMBER(10) NOT NULL,
    pret NUMBER(10,2) NOT NULL,
    CONSTRAINT pk_comanda_produs PRIMARY KEY (id_comanda, id_produs),
    CONSTRAINT fk_comanda_produs_comanda FOREIGN KEY (id_comanda) REFERENCES COMANDA(id_comanda),
    CONSTRAINT fk_comanda_produs_produs FOREIGN KEY (id_produs) REFERENCES PRODUS(id_produs)
);

INSERT INTO TRANSPORT VALUES (seq_transport.nextval, 'Fan Courier', 2, 19.99);
INSERT INTO TRANSPORT VALUES (seq_transport.nextval, 'DPD', 3, 15.50);
INSERT INTO TRANSPORT VALUES (seq_transport.nextval, 'Sameday', 1, 12.00);
INSERT INTO TRANSPORT VALUES (seq_transport.nextval, 'Cargus', 4, 18.30);
INSERT INTO TRANSPORT VALUES (seq_transport.nextval, 'Bookurier', 2, 10.00);

INSERT INTO MOD_PLATA VALUES (seq_modplata.nextval, 'cash');
INSERT INTO MOD_PLATA VALUES (seq_modplata.nextval, 'card');
INSERT INTO MOD_PLATA VALUES (seq_modplata.nextval, 'cash');
INSERT INTO MOD_PLATA VALUES (seq_modplata.nextval, 'card');
INSERT INTO MOD_PLATA VALUES (seq_modplata.nextval, 'cash');
INSERT INTO MOD_PLATA VALUES (seq_modplata.nextval, 'card');
INSERT INTO MOD_PLATA VALUES (seq_modplata.nextval, 'cash');
INSERT INTO MOD_PLATA VALUES (seq_modplata.nextval, 'card');
INSERT INTO MOD_PLATA VALUES (seq_modplata.nextval, 'cash');
INSERT INTO MOD_PLATA VALUES (seq_modplata.nextval, 'card');

INSERT INTO CASH VALUES (1, 'RON');
INSERT INTO CASH VALUES (3, 'EUR');
INSERT INTO CASH VALUES (5, 'USD');
INSERT INTO CASH VALUES (7, 'RON');
INSERT INTO CASH VALUES (9, 'EUR');

INSERT INTO CARD VALUES (2, '1234123412341234', TO_DATE('2026-10-10','YYYY-MM-DD'), 'Visa');
INSERT INTO CARD VALUES (4, '5678567856785678', TO_DATE('2025-12-31','YYYY-MM-DD'), 'MasterCard');
INSERT INTO CARD VALUES (6, '9999888877776666', TO_DATE('2027-01-01','YYYY-MM-DD'), 'Visa');
INSERT INTO CARD VALUES (8, '4444333322221111', TO_DATE('2025-09-30','YYYY-MM-DD'), 'Maestro');
INSERT INTO CARD VALUES (10, '1111222233334444', TO_DATE('2026-03-15','YYYY-MM-DD'), 'Revolut');

INSERT INTO CLIENT VALUES (seq_client.nextval, 'Ion Popescu', TO_DATE('2024-01-01','YYYY-MM-DD'), 'persoana fizica');
INSERT INTO CLIENT VALUES (seq_client.nextval, 'SC Tehnoserv SRL', TO_DATE('2024-02-01','YYYY-MM-DD'), 'persoana juridica');
INSERT INTO CLIENT VALUES (seq_client.nextval, 'Maria Ionescu', TO_DATE('2024-03-01','YYYY-MM-DD'), 'persoana fizica');
INSERT INTO CLIENT VALUES (seq_client.nextval, 'Andrei Dumitrescu', TO_DATE('2024-04-01','YYYY-MM-DD'), 'persoana fizica');
INSERT INTO CLIENT VALUES (seq_client.nextval, 'DigitalNet Solutions', TO_DATE('2024-05-01','YYYY-MM-DD'), 'persoana juridica');

INSERT INTO PRODUCATOR VALUES (seq_producator.nextval, 'Zentari Corp', 'Romania', '1234567890');
INSERT INTO PRODUCATOR VALUES (seq_producator.nextval, 'Novera Ltd', 'Polonia', '0987654321');
INSERT INTO PRODUCATOR VALUES (seq_producator.nextval, 'Veltria GmbH', 'Germania', '5678901234');
INSERT INTO PRODUCATOR VALUES (seq_producator.nextval, 'Auralis S.p.A.', 'Italia', '1122334455');
INSERT INTO PRODUCATOR VALUES (seq_producator.nextval, 'Solvexa SARL', 'Franta', '5566778899');

INSERT INTO PRODUS VALUES (seq_produs.NEXTVAL, 'pix albastru', 'papetarie');
INSERT INTO PRODUS VALUES (seq_produs.NEXTVAL, 'caiet A5', 'papetarie');
INSERT INTO PRODUS VALUES (seq_produs.NEXTVAL, 'agenda', 'papetarie');
INSERT INTO PRODUS VALUES (seq_produs.NEXTVAL, 'mapa plastic', 'organizare birou');
INSERT INTO PRODUS VALUES (seq_produs.NEXTVAL, 'creion mecanic', 'papetarie');
INSERT INTO PRODUS VALUES (seq_produs.NEXTVAL, 'marker permanent', 'papetarie');
INSERT INTO PRODUS VALUES (seq_produs.NEXTVAL, 'dosar carton', 'organizare birou');
INSERT INTO PRODUS VALUES (seq_produs.NEXTVAL, 'set acuarele', 'arta');
INSERT INTO PRODUS VALUES (seq_produs.NEXTVAL, 'lipici solid', 'papetarie');
INSERT INTO PRODUS VALUES (seq_produs.NEXTVAL, 'taietor hartie', 'organizare birou');

INSERT INTO STOC VALUES (1, 1, 50, 4000.00, 3, TO_DATE('2025-05-01', 'YYYY-MM-DD'), 1.5, TO_DATE('2025-08-01', 'YYYY-MM-DD'));
INSERT INTO STOC VALUES (1, 2, 30, 3950.00, 3, TO_DATE('2025-05-03', 'YYYY-MM-DD'), 1.4, TO_DATE('2025-08-05', 'YYYY-MM-DD'));
INSERT INTO STOC VALUES (2, 1, 60, 5000.00, 3, TO_DATE('2025-05-02', 'YYYY-MM-DD'), 2.0, TO_DATE('2025-07-20', 'YYYY-MM-DD'));
INSERT INTO STOC VALUES (2, 3, 45, 5100.00, 3, TO_DATE('2025-04-28', 'YYYY-MM-DD'), 1.8, TO_DATE('2025-07-15', 'YYYY-MM-DD'));
INSERT INTO STOC VALUES (3, 2, 100, 150.00, 3, TO_DATE('2025-05-05', 'YYYY-MM-DD'), 0.5, TO_DATE('2025-06-30', 'YYYY-MM-DD'));
INSERT INTO STOC VALUES (3, 4, 80, 160.00, 3, TO_DATE('2025-04-30', 'YYYY-MM-DD'), 0.6, TO_DATE('2025-07-01', 'YYYY-MM-DD'));
INSERT INTO STOC VALUES (4, 5, 70, 300.00, 3, TO_DATE('2025-05-06', 'YYYY-MM-DD'), 1.0, TO_DATE('2025-09-15', 'YYYY-MM-DD'));
INSERT INTO STOC VALUES (4, 1, 65, 290.00, 3, TO_DATE('2025-05-01', 'YYYY-MM-DD'), 1.2, TO_DATE('2025-09-10', 'YYYY-MM-DD'));
INSERT INTO STOC VALUES (5, 3, 40, 800.00, 3, TO_DATE('2025-04-15', 'YYYY-MM-DD'), 3.0, TO_DATE('2025-10-01', 'YYYY-MM-DD'));
INSERT INTO STOC VALUES (5, 2, 35, 820.00, 3, TO_DATE('2025-05-07', 'YYYY-MM-DD'), 2.8, TO_DATE('2025-09-28', 'YYYY-MM-DD'));


INSERT INTO CONTACTE_CLIENT VALUES (seq_contacte_client.nextval, 1, 'telefon', '0712345678', 'activ');
INSERT INTO CONTACTE_CLIENT VALUES (seq_contacte_client.nextval, 2, 'email', 'client@company.com', 'activ');
INSERT INTO CONTACTE_CLIENT VALUES (seq_contacte_client.nextval, 3, 'adresa', 'Str. Exemplu 10, Bucuresti', 'activ');
INSERT INTO CONTACTE_CLIENT VALUES (seq_contacte_client.nextval, 4, 'telefon', '0723456789', 'inactiv');
INSERT INTO CONTACTE_CLIENT VALUES (seq_contacte_client.nextval, 5, 'email', 'contact@firma.ro', 'activ');

INSERT INTO BONUSURI VALUES (seq_bonusuri.nextval, 1, 50.00, TO_DATE('2025-12-31', 'YYYY-MM-DD'));
INSERT INTO BONUSURI VALUES (seq_bonusuri.nextval, 2, 25.00, TO_DATE('2025-06-30', 'YYYY-MM-DD'));
INSERT INTO BONUSURI VALUES (seq_bonusuri.nextval, 3, 75.00, NULL);
INSERT INTO BONUSURI VALUES (seq_bonusuri.nextval, 4, 100.00, TO_DATE('2025-05-15', 'YYYY-MM-DD'));
INSERT INTO BONUSURI VALUES (seq_bonusuri.nextval, 5, 30.00, TO_DATE('2025-11-30', 'YYYY-MM-DD'));

INSERT INTO COMANDA VALUES (seq_comanda.nextval, 1, 1, 1, TO_DATE('2025-05-01', 'YYYY-MM-DD'), 'in proces');
INSERT INTO COMANDA VALUES (seq_comanda.nextval, 2, 2, 2, TO_DATE('2025-05-02', 'YYYY-MM-DD'), 'livrata');
INSERT INTO COMANDA VALUES (seq_comanda.nextval, 3, 3, 3, TO_DATE('2025-05-03', 'YYYY-MM-DD'), 'anulata');
INSERT INTO COMANDA VALUES (seq_comanda.nextval, 4, 4, 4, TO_DATE('2025-05-04', 'YYYY-MM-DD'), 'in proces');
INSERT INTO COMANDA VALUES (seq_comanda.nextval, 5, 5, 5, TO_DATE('2025-05-05', 'YYYY-MM-DD'), 'livrata');

INSERT INTO RECENZIE VALUES (seq_recenzie.nextval, 1, 1, 1, 5, TO_DATE('2025-05-06', 'YYYY-MM-DD'));
INSERT INTO RECENZIE VALUES (seq_recenzie.nextval, 2, 2, 3, 4, TO_DATE('2025-05-07', 'YYYY-MM-DD'));
INSERT INTO RECENZIE VALUES (seq_recenzie.nextval, 3, 3, 4, 3, TO_DATE('2025-05-08', 'YYYY-MM-DD'));
INSERT INTO RECENZIE VALUES (seq_recenzie.nextval, 4, 5, 2, 2, TO_DATE('2025-05-09', 'YYYY-MM-DD'));
INSERT INTO RECENZIE VALUES (seq_recenzie.nextval, 5, 1, 1, 1, TO_DATE('2025-05-10', 'YYYY-MM-DD'));
INSERT INTO RECENZIE VALUES (seq_recenzie.nextval, 3, 2, 3, 4, TO_DATE('2025-05-11', 'YYYY-MM-DD'));
INSERT INTO RECENZIE VALUES (seq_recenzie.nextval, 4, 4, 5, 5, TO_DATE('2025-05-12', 'YYYY-MM-DD'));

INSERT INTO REDUCERE VALUES (seq_reducere.nextval, 1, 1, 10, 'automat', 'da');
INSERT INTO REDUCERE VALUES (seq_reducere.nextval, 2, 3, 15, 'cod promotional', 'nu');
INSERT INTO REDUCERE VALUES (seq_reducere.nextval, 3, 4, 20, 'automat', 'da');
INSERT INTO REDUCERE VALUES (seq_reducere.nextval, 4, 1, 5, 'cod promotional', 'da');
INSERT INTO REDUCERE VALUES (seq_reducere.nextval, 5, 2, 30, 'automat', 'nu');
INSERT INTO REDUCERE VALUES (seq_reducere.nextval, 2, 1, 15, 'cod promotional', 'nu');
INSERT INTO REDUCERE VALUES (seq_reducere.nextval, 3, 2, 17, 'automat', 'da');

INSERT INTO COMANDA_PRODUS VALUES (1, 1, 2, 19.99);
INSERT INTO COMANDA_PRODUS VALUES (2, 2, 1, 15.50);
INSERT INTO COMANDA_PRODUS VALUES (3, 3, 1, 12.00);
INSERT INTO COMANDA_PRODUS VALUES (4, 4, 3, 18.30);
INSERT INTO COMANDA_PRODUS VALUES (5, 5, 2, 10.00);
INSERT INTO COMANDA_PRODUS VALUES (1, 4, 1, 19.99);
INSERT INTO COMANDA_PRODUS VALUES (2, 1, 2, 15.50);
INSERT INTO COMANDA_PRODUS VALUES (3, 2, 3, 12.00);
INSERT INTO COMANDA_PRODUS VALUES (4, 5, 1, 18.30);
INSERT INTO COMANDA_PRODUS VALUES (5, 3, 2, 10.00);

