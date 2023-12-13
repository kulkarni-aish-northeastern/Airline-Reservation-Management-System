------------------------------------------------------------------------------------
-- Project - SkyReserve: Airline Management System

------------------------------------------------------------------------------------

------------------------------------------------------------------------------------
-- ORDER OF EXECUTION
/*
	1. Create Encryption (run alone)
	2. Create Functions (run one by one)
	3. Create Tables 
	4. Create Triggers (run alone)
	5. Function to generate computed column (run alone)
	6. Insert Data
	7. Create Views (run one by one)
	8. Show Views
	9. Test Cases For Functions, Triggers, and Check Constraints (run one by one)
	10. Select Statements for all tables 
	11. Clean-up Using HouseKeeping Commands
*/
--==================================================================================

USE AirlineReservationTeam5;

--==================================================================================
/*========================================= ENCRYPTION MASTER CODE ===============================================*/

-- Create DMK
CREATE MASTER KEY
ENCRYPTION BY PASSWORD = 'Team_5_encryption';

-- Create certificate to protect symmetric key
CREATE CERTIFICATE TestCertificate
WITH SUBJECT = 'to_encrypt',
EXPIRY_DATE = '2026-10-31';

-- Create symmetric key to encrypt data
CREATE SYMMETRIC KEY SymmetricKey
WITH ALGORITHM = AES_128
ENCRYPTION BY CERTIFICATE TestCertificate;

-- Open symmetric key
OPEN SYMMETRIC KEY SymmetricKey
DECRYPTION BY CERTIFICATE TestCertificate;


/*========================================= CREATE TABLE-LEVEL CHECK CONSTRAINT =========================================*/
GO
/* Baggage weight cannot exceed 50 lbs */
CREATE FUNCTION CheckBaggageWeightLimit(@Weight INT)
RETURNS BIT
AS
BEGIN
    DECLARE @Result BIT;
    IF @Weight <= 50

        SET @Result = 1;
    ELSE
        SET @Result = 0;

    RETURN @Result;
END;
GO
/* Constraint to make sure that supporting documents have been provided by students before making student reservation
to get student benefits*/
CREATE FUNCTION CheckStudentSupportingDocument(@SupportingDocuments BIT)
RETURNS BIT
AS
BEGIN
    DECLARE @Result BIT;
	IF @SupportingDocuments = 1
	     SET @Result = 1
	ELSE
	     SET @Result = 0
	RETURN @Result;
END;

/*========================================= CREATING ALL THE TABLES CORRESPONDING TO ENTITIES IN ERD =========================================*/
CREATE TABLE Airport (
             AirportCode VARCHAR(5) NOT NULL PRIMARY KEY,
			 AirportName VARCHAR(100) NOT NULL,
			 AirportLocation VARCHAR(100) NOT NULL,
			 TimeZone VARCHAR(40) NOT NULL, 
			 ContactInformation BIGINT NOT NULL,
			 CONSTRAINT CHK_Airport_ContactInformation CHECK (ContactInformation >= 1000000000 AND ContactInformation <= 9999999999)

);

CREATE TABLE LoyaltyProgram(
			 ProgramID INT IDENTITY(1,1) NOT NULL PRIMARY KEY, 
			 ProgramName VARCHAR(20) NOT NULL
);

CREATE TABLE Airline(
			 AirlineCode VARCHAR(5) NOT NULL PRIMARY KEY,
			 ProgramID INT NOT NULL REFERENCES LoyaltyProgram (ProgramID),
			 PhoneNumber BIGINT NOT NULL,
			 Country VARCHAR(10) NOT NULL,
			 AirlineName VARCHAR(30) NOT NULL,
			 CONSTRAINT CHK_Airline_PhoneNumber CHECK (PhoneNumber >= 1000000000 AND PhoneNumber <= 9999999999)
);


CREATE TABLE Flight (
             FlightNumber VARCHAR(20) NOT NULL PRIMARY KEY,
			 AirlineCode VARCHAR(5) NOT NULL REFERENCES Airline (AirlineCode),
			 DestinationAirport VARCHAR(5) NOT NULL REFERENCES Airport (AirportCode),
			 DepartureAirport VARCHAR(5) NOT NULL REFERENCES Airport (AirportCode),
			 ArrivalTime DATETIME NOT NULL, -- YYYY-MM-DD HH:MM:SS
			 FlightDuration TIME NOT NULL, -- HH:MM:SS
			 AvailableSeats INT NOT NULL,
			 AircraftType VARCHAR(50) NOT NULL,
			 DepartureTime DATETIME NOT NULL -- YYYY-MM-DD HH:MM:SS
);

CREATE TABLE Passenger (
             PassengerID INT IDENTITY(100,1) NOT NULL PRIMARY KEY,
             ProgramID INT NOT NULL REFERENCES LoyaltyProgram (ProgramID),
             FirstName VARCHAR(30) NOT NULL ,
			 LastName VARCHAR(30) NOT NULL ,
			 Gender VARCHAR(20) NOT NULL ,
			 DateOfBirth DATE NOT NULL
);

CREATE TABLE Reservation (
             ReservationID INT IDENTITY(1000,1) NOT NULL PRIMARY KEY,
			 FlightNumber VARCHAR(20) NOT NULL REFERENCES Flight (FlightNumber),
			 PassengerID INT NOT NULL REFERENCES Passenger (PassengerID),
			 SeatNumber VARCHAR(3) NOT NULL,
			 TicketPrice MONEY NOT NULL,
			 ReservationStatus VARCHAR(10) NOT NULL,
			 PaymentStatus VARCHAR(10) NOT NULL,
			 BookingDate DATE NOT NULL, -- YYYY-MM-DD
			 "Fare (after discounts & tax)" MONEY
);

CREATE TABLE TravelInsurance (
             InsurancePolicyNumber INT IDENTITY(10000,1) NOT NULL PRIMARY KEY,
			 ReservationID INT NOT NULL REFERENCES Reservation (ReservationID),
			 StartDate DATE NOT NULL,
			 EndDate DATE NOT NULL,
			 PhoneNumber BIGINT NOT NULL,
			 CONSTRAINT CHK_TravelInsurance_PhoneNumber CHECK (PhoneNumber >= 1000000000 AND PhoneNumber <= 9999999999)
);

CREATE TABLE CoverageDetails (
             CoverageDetailsID INT IDENTITY(2000,1) NOT NULL PRIMARY KEY,
			 InsurancePolicyNumber INT NOT NULL REFERENCES TravelInsurance (InsurancePolicyNumber),
			 TripCancellation BIT NOT NULL,
			 EmergencyMedical BIT NOT NULL,
			 BaggageLossDelay BIT NOT NULL,
			 TravelDelay BIT NOT NULL,
			 TripInterruption BIT NOT NULL
);

CREATE TABLE PaymentTransaction (
             TransactionID INT IDENTITY(3000,1) NOT NULL PRIMARY KEY,
			 ReservationID INT NOT NULL REFERENCES Reservation (ReservationID),
			 PaymentAmount MONEY NOT NULL,
			 PaymentMethod VARCHAR(20) NOT NULL,
			 CardNumber VARBINARY(300) NOT NULL, /* Encrypted attribute */
			 PaymentStatus VARCHAR(10) NOT NULL,
			 TransactionDateTime DATETIME NOT NULL -- YYYY-MM-DD HH:MM:SS
);

CREATE TABLE StudentGroupBooking(
             GroupBookingID INT IDENTITY(500,1) NOT NULL PRIMARY KEY,
             FlightNumber VARCHAR(20) NOT NULL REFERENCES Flight (FlightNumber)
);

CREATE TABLE Student (
             StudentID VARCHAR(10) NOT NULL PRIMARY KEY,
			 GroupBookingID INT REFERENCES StudentGroupBooking(GroupBookingID),
			 PassengerID INT NOT NULL REFERENCES Passenger (PassengerID),
			 FirstName VARCHAR(30) NOT NULL, 
			 LastName VARCHAR(30) NOT NULL,
             DateofBirth DATE NOT NULL,
             Nationality VARCHAR(15) NOT NULL,
             SchoolName VARCHAR(50) NOT NULL,
             SchoolEmailID VARCHAR(100)NOT NULL,
);

CREATE TABLE StudentBenefit(
			 StudentBenefitID INT IDENTITY(400,1) NOT NULL PRIMARY KEY,
			 GroupBookingID INT NOT NULL REFERENCES StudentGroupBooking (GroupBookingID),
			 DiscountPercentage INT NOT NULL,
			 EnrollmentStatus VARCHAR(50) NOT NULL,
			 SupportingDocumentationProvided BIT NOT NULL,
			 AirportLoungeAccess BIT NOT NULL,
			 FreeCancellation BIT NOT NULL,
			 DiscountedAirMeals BIT NOT NULL,
			 StudentFareLock BIT NOT NULL,
			 FreeWiFiAccess BIT NOT NULL,
			 ExpiryDate DATE NOT NULL
);

-- ADD CONSTRAINT ON STUDENTBENEFIT TABLE TO MAKE SURE THAT SUPPORTING DOCUMENTS ARE PROVIDED
ALTER TABLE StudentBenefit ADD CONSTRAINT CheckSupportingDocuments CHECK (dbo.CheckStudentSupportingDocument(SupportingDocumentationProvided) = 1);


CREATE TABLE Feedback (
             FeedbackID INT IDENTITY(5000,1) NOT NULL PRIMARY KEY,
			 ReservationID INT NOT NULL REFERENCES Reservation (ReservationID),
			 PassengerID INT NOT NULL REFERENCES Passenger (PassengerID),
			 FeedbackDate DATE NOT NULL
);


CREATE TABLE RedemptionOptions (
             RedemptionID INT IDENTITY(70,1) NOT NULL PRIMARY KEY,
			 ProgramID INT NOT NULL REFERENCES LoyaltyProgram (ProgramID),
			 RedemptionPoints INT NOT NULL,
			 RedemptionValidity DATE NOT NULL
);

CREATE TABLE ProgramBenefits (
             BenefitID INT IDENTITY(800,1) NOT NULL PRIMARY KEY,
			 ProgramID INT NOT NULL REFERENCES LoyaltyProgram (ProgramID),
			 BenefitType VARCHAR(50) NOT NULL,
			 BenefitEligibility BIT NOT NULL,
             BenefitValue MONEY NOT NULL
);

CREATE TABLE Baggage (
             BaggageID INT IDENTITY(900,1) NOT NULL PRIMARY KEY,
			 BaggageWeight INT NOT NULL,
			 BaggageLength INT NOT NULL,
			 BaggageHeight INT NOT NULL,
			 BaggageWidth INT NOT NULL,
			 BaggageStatus VARCHAR(50) NOT NULL
);

-- ADD CONSTRAINT ON BAGGAGE TABLE TO LIMIT BAGGAGE WEIGHT
ALTER TABLE Baggage ADD CONSTRAINT CheckBaggageWeight CHECK(dbo.CheckBaggageWeightLimit(BaggageWeight) = 1);


CREATE TABLE BaggageTracking (
             BaggageID INT NOT NULL REFERENCES Baggage (BaggageID),
             PassengerID INT NOT NULL REFERENCES Passenger (PassengerID),
             BaggageTrackingStatus VARCHAR(50) NOT NULL,
             LastTrackingDate DATE NOT NULL,
             PRIMARY KEY (BaggageID, PassengerID)
);

CREATE TABLE Country (
			 CountryID VARCHAR(10) NOT NULL PRIMARY KEY,
			 CountryName VARCHAR(50) NOT NULL
);

CREATE TABLE AirlineCompany ( 
			 AirlineCode VARCHAR(5) NOT NULL REFERENCES Airline (AirlineCode),
			 CountryID VARCHAR(10) NOT NULL REFERENCES Country (CountryID),
			 PRIMARY KEY (AirlineCode, CountryID),
);


/*========================================= TRIGGER TO UPDATE FARE IN RESERVATION TABLE =========================================*/

CREATE TRIGGER CalculateFareBasedOnDiscount
ON Reservation
AFTER INSERT
AS
BEGIN
    WITH FareCTE AS (
        SELECT i.ReservationID, 
		       i.PassengerID, 
			   i.TicketPrice, 
			   s.PassengerID AS [StudentPassengerID],
			   s.GroupBookingID,
			   (i.TicketPrice+((i.TicketPrice*4)/100)) AS InitialFare,
               CASE
                   WHEN s.GroupBookingID IS NOT NULL THEN sb.DiscountPercentage
				   WHEN s.PassengerID IS NOT NULL AND s.GroupBookingID IS NULL THEN 10
                   ELSE 0
               END AS DiscountPercentage
        FROM inserted i
        LEFT JOIN Student s ON i.PassengerID = s.PassengerID
        LEFT JOIN StudentBenefit sb ON s.GroupBookingID = sb.GroupBookingID
    )
    UPDATE r
    SET
        "Fare (after discounts & tax)" = ((i.TicketPrice + ((i.TicketPrice*4)/100)) * (1 - (fc.DiscountPercentage / 100.0)))
    FROM Reservation r
    INNER JOIN inserted i ON r.ReservationID = i.ReservationID
    INNER JOIN FareCTE fc ON r.ReservationID = fc.ReservationID;
END;
/**************************************************************** END OF TRIGGERS ****************************************************************/
GO
/*============================ FUNCTION TO GENERATE COMPUTED COLUMN AND ALTER TABLE TRAVELINSURANCE TABLE AFTERWARDS ============================*/

CREATE FUNCTION dbo.CalculateInsuranceCost(@ReservationID INT)
RETURNS MONEY
AS
BEGIN
    DECLARE @InsuranceCost MONEY = 0.00;
    DECLARE @StartDate DATE;
    DECLARE @EndDate DATE;

    -- Retrieve the StartDate and EndDate from the TravelInsurance table based on ReservationID
    SELECT @StartDate = StartDate, @EndDate = EndDate
    FROM TravelInsurance
    WHERE ReservationID = @ReservationID;

    -- Calculate the duration of coverage in days
    DECLARE @CoverageDays INT = DATEDIFF(DAY, @StartDate, @EndDate) + 1;

        SET @InsuranceCost = @CoverageDays * 10.00; -- Assuming $10 per day of coverage

    RETURN @InsuranceCost;
END;


/**************************************** INSERTING DATA IN TABLES *********************************************/

INSERT INTO Airport(AirportCode, AirportName, AirportLocation, TimeZone, ContactInformation) 
            VALUES('SJC', 'San Jose Airport', 'San Jose, USA', 'America/Los_Angeles', 1123456788),
                  ('JFK', 'John F. Kennedy International Airport', 'New York, USA', 'America/New_York', 1234567890),
                  ('CDG', 'Charles de Gaulle Airport', 'Paris, France', 'Europe/Paris', 7890123456),
                  ('LAX', 'Los Angeles International Airport', 'Los Angeles, USA', 'America/Los_Angeles', 9876543210),
                  ('AMS', 'Amsterdam Airport Schiphol', 'Amsterdam, Netherlands', 'Europe/Amsterdam', 2345678901),
                  ('HND', 'Haneda Airport', 'Tokyo, Japan', 'Asia/Tokyo', 5678901234),
                  ('SIN', 'Singapore Changi Airport', 'Singapore', 'Asia/Singapore', 9012345678),
                  ('DXB', 'Dubai International Airport', 'Dubai, UAE', 'Asia/Dubai', 3456789012),
                  ('SYD', 'Sydney Kingsford Smith Airport', 'Sydney, Australia', 'Australia/Sydney', 6789012345),
                  ('JNB', 'O.R. Tambo International Airport', 'Johannesburg, South Africa', 'Africa/Johannesburg', 4321098765),
                  ('IST', 'Istanbul Airport', 'Istanbul, Turkey', 'Europe/Istanbul', 9876543210),
                  ('HKG', 'Hong Kong International Airport', 'Hong Kong', 'Asia/Hong_Kong', 2109876543),
                  ('ATL', 'Hartsfield-Jackson Atlanta International Airport', 'Atlanta, USA', 'America/New_York', 5432109876),
                  ('FRA', 'Frankfurt Airport', 'Frankfurt, Germany', 'Europe/Berlin', 3210987654),
                  ('KUL', 'Kuala Lumpur International Airport', 'Kuala Lumpur, Malaysia', 'Malaysia/Kuala_Lumpur', 6038776200);


INSERT INTO LoyaltyProgram (ProgramName)
            VALUES('Sky Miles'),
                  ('Miles & Smiles'),
				  ('Air Points'),
                  ('Frequent Flyer'),
				  ('Travel Rewards'),
				  ('Bonus Miles'),
				  ('Points Plus'),
				  ('MileagePlus'),
				  ('Rewards Club'),
				  ('SkyRewards'),
			      ('Travel Miles'),
				  ('Loyalty Points'),
				  ('Miles&More'),
				  ('SkyRewards Plus'),
				  ('Flyer Bonus');

INSERT INTO Airline(AirlineCode, ProgramID, PhoneNumber, Country, AirlineName) 
            VALUES('EK', 1 , 1234567890, 'UAE', 'Emirates'),
			      ('BA', 2, 9876543210, 'UK', 'British Airways'),
				  ('AA', 4, 8765432109, 'USA', 'American Airlines'),
				  ('DL', 3, 7654321098, 'USA', 'Delta Airlines'),
				  ('UA', 9, 6543210987, 'USA', 'United Airlines'),
				  ('LH', 5, 5432109876, 'Germany', 'Lufthansa'),
				  ('SQ', 8, 4321098765, 'Singapore', 'Singapore Airlines'),
				  ('QF', 15, 2109876543, 'Australia', 'Qantas'),
				  ('TK', 11, 9876543210, 'Turkey', 'Turkish Airlines'),
				  ('EY', 12, 7654321098, 'UAE', 'Etihad Airways'),
				  ('CX', 14, 5432109876, 'Hong Kong', 'Cathay Pacific'),
				  ('AF', 13, 1098765432, 'France', 'Air France'),
				  ('MH', 7, 6543210987, 'Malaysia', 'Malaysia Airlines'),
				  ('QR', 6, 8765432109, 'Qatar', 'Qatar Airways');

INSERT INTO Flight (FlightNumber, AirlineCode, DestinationAirport, DepartureAirport, ArrivalTime, FlightDuration, AvailableSeats, AircraftType, DepartureTime) 
VALUES('EK456', 'EK', 'DXB', 'SIN', '2023-08-10 14:30:00', '07:30:00', 220, 'Airbus A380', '2023-08-10 07:00:00'),
      ('BA123', 'BA', 'JNB', 'JFK', '2023-07-27 15:30:00', '08:30:00', 150, 'Boeing 777', '2023-07-27 07:00:00'),
      ('AA456', 'AA', 'LAX', 'IST', '2023-07-28 12:45:00', '05:15:00', 200, 'Airbus A320', '2023-07-28 07:30:00'),
      ('DL789', 'DL', 'ATL', 'DXB', '2023-07-29 17:15:00', '04:45:00', 180, 'Boeing 737', '2023-07-29 12:30:00'),
      ('UA234', 'UA', 'SJC', 'HKG', '2023-07-30 19:00:00', '03:00:00', 120, 'Airbus A380', '2023-07-30 16:00:00'),
      ('LH567', 'LH', 'FRA', 'CDG', '2023-07-31 10:00:00', '01:15:00', 250, 'Boeing 747', '2023-07-31 08:45:00'),
      ('EK901', 'EK', 'DXB', 'JFK', '2023-08-01 17:00:00', '10:30:00', 300, 'Airbus A350', '2023-08-01 06:30:00'),
      ('SQ345', 'SQ', 'SIN', 'KUL', '2023-08-02 17:00:00', '10:30:00', 350, 'Boeing 787', '2023-08-02 06:30:00'),
      ('QF678', 'QF', 'SYD', 'SIN', '2023-08-03 19:00:00', '08:00:00', 400, 'Airbus A330', '2023-08-03 11:00:00'),
      ('TK789', 'TK', 'SJC', 'AMS', '2023-08-04 16:20:00', '03:40:00', 300, 'Boeing 777', '2023-08-04 12:40:00'),
      ('EY123', 'EY', 'HND', 'JFK', '2023-08-05 18:20:00', '02:00:00', 250, 'Airbus A380', '2023-08-05 16:20:00'),
      ('CX456', 'CX', 'HKG', 'LAX', '2023-08-07 01:30:00', '13:30:00', 200, 'Boeing 777', '2023-08-06 12:00:00'),
      ('AF789', 'AF', 'CDG', 'SYD', '2023-08-07 11:45:00', '08:15:00', 300, 'Airbus A380', '2023-08-07 03:30:00'),
      ('MH234', 'MH', 'KUL', 'ATL', '2023-08-08 20:15:00', '08:45:00', 180, 'Boeing 737', '2023-08-08 11:30:00'),
      ('QR567', 'QR', 'JNB', 'CDG', '2023-08-10 05:30:00', '06:30:00', 250, 'Airbus A350', '2023-08-09 22:00:00');

INSERT INTO Passenger (ProgramID, FirstName, LastName, Gender, DateOfBirth) 
            VALUES(1, 'John', 'Doe', 'Male', '1980-01-01'),
				  (2, 'Emily', 'Johnson', 'Female', '1992-05-10'),
				  (8, 'Michael', 'Smith', 'Male', '1985-09-20'),
				  (10, 'Emma', 'Williams', 'Female', '1998-03-15'),
				  (5, 'Daniel', 'Brown', 'Male', '1990-11-28'),
				  (6, 'Olivia', 'Martinez', 'Female', '1987-12-05'),
				  (7, 'William', 'Davis', 'Male', '1994-08-14'),
				  (8, 'Sophia', 'Garcia', 'Female', '1989-06-22'),
				  (9, 'James', 'Rodriguez', 'Male', '1996-02-18'),
				  (10, 'Isabella', 'Hernandez', 'Female', '1984-04-12'),
				  (11, 'Alexander', 'Lopez', 'Male', '1999-07-03'),
				  (12, 'Charlotte', 'Taylor', 'Female', '1993-10-27'),
				  (13, 'Mason', 'Gonzalez', 'Male', '1986-12-08'),
				  (4, 'Amelia', 'Wilson', 'Female', '1991-09-16'),
				  (5, 'Ethan', 'Miller', 'Male', '1997-11-23'),
				  (7, 'Ava', 'Martinez', 'Female', '1988-08-07'),
				  (15, 'Liam', 'Johnson', 'Male', '1991-04-30'),
				  (12, 'Oliver', 'Smith', 'Male', '1989-02-14'),
				  (3, 'Sophia', 'Davis', 'Female', '1995-06-26'),
				  (5, 'Lucas', 'Brown', 'Male', '1993-12-19'),
				  (9, 'Mia', 'Williams', 'Female', '1996-10-09'),
				  (11, 'Ethan', 'Taylor', 'Male', '1987-11-11'),
				  (6, 'Isabella', 'Garcia', 'Female', '1992-03-22'),
				  (1, 'Jackson', 'Rodriguez', 'Male', '1994-09-05'),
				  (4, 'Emma', 'Lopez', 'Female', '1998-01-12');

INSERT INTO StudentGroupBooking (FlightNumber) 
            VALUES('EK456'),
			      ('CX456'),
				  ('TK789'),
				  ('SQ345'),
				  ('QF678'),
				  ('UA234') ,
				  ('EY123'), 
				  ('CX456'), 
				  ('AF789'), 
				  ('MH234');

INSERT INTO Student (StudentID, GroupBookingID, PassengerID, FirstName, LastName, DateofBirth, Nationality, SchoolName, SchoolEmailID) 
            VALUES('002754719', 500, 102, 'Michael', 'Smith', '1985-09-20', 'American', 'City High School', 'michael.smith@chs.edu'),
			      ('002457878', 501, 105, 'Olivia', 'Martinez', '1987-12-05', 'Mexican', 'Suburb High School', 'olivia.mar@shs.edu'),
                  ('002457896', 501, 121, 'Ethan', 'Taylor', '1987-11-11', 'Canadian', 'Suburb High School', 'ethan.t@shs.edu'),
				  ('004157896', 501, 118, 'Sophia', 'Davis', '1995-06-26', 'British', 'Suburb High School', 'sophia.davis1@shs.edu'),
				  ('002145796', 500, 119, 'Lucas', 'Brown', '1993-12-19', 'American', 'City High School', 'lucas.brown@chs.edu'),
				  ('007845962', 500, 111, 'Charlotte', 'Taylor', '1993-10-27', 'Canadian', 'City High School' , 'ctaylor@chs.edu'),
                  ('002145793', 500, 116, 'Liam', 'Johnson', '1991-04-30', 'Mexican', 'City High School', 'johnson.l@chs.edu'),
                  ('002345678', NULL, 117, 'Oliver', 'Smith', '1989-02-14','American', 'City High School', 'o.smith@chs.edu'),
				  ('002345688', NULL, 101, 'Emily', 'Johnson', '1992-05-10', 'African', 'Northeastern University', 'emily.johnson@northeastern.edu'),
				  ('002144589', NULL, 120, 'Mia', 'Williams', '1996-10-09', 'European', 'San Jose State University', 'm.williams@sjsu.edu');
				  
INSERT INTO StudentBenefit (GroupBookingID, DiscountPercentage, EnrollmentStatus, SupportingDocumentationProvided
                            ,AirportLoungeAccess, FreeCancellation, DiscountedAirMeals, StudentFareLock, FreeWiFiAccess, ExpiryDate) 
            VALUES(500, 20, 'Enrolled', 1, 1, 0, 0, 0, 1,'2023-03-31'),
			      (501, 15, 'Enrolled', 1, 1, 1, 1, 0, 0,'2023-04-15'),
				  (502, 12, 'Enrolled', 1, 0, 1, 1, 0, 0, '2023-03-19'),
				  (503, 14, 'Enrolled', 1, 0, 1, 1, 1, 1, '2023-04-20'),
				  (504, 18, 'Enrolled', 1, 0, 0, 1, 1, 1, '2023-06-25'),
				  (505, 19, 'Enrolled', 1, 1, 0, 0, 1, 1, '2023-07-25'),
				  (506, 17, 'Enrolled' ,1, 0, 0, 1, 1, 0, '2023-04-16'),
				  (507, 5, 'Enrolled', 1, 0, 1, 1, 1, 1, '2023-11-12'),
                  (508, 7, 'Enrolled', 1, 1, 1, 0, 1, 0, '2023-10-17'),
                  (509, 9, 'Enrolled', 1, 1, 0, 1, 0, 0, '2023-12-15');

INSERT INTO Reservation (FlightNumber, PassengerID, SeatNumber, TicketPrice, ReservationStatus, PaymentStatus, BookingDate) 
            VALUES('EK456', 100, '1A', 1000.00, 'Confirmed', 'Paid', '2023-03-01'),
				  ('AA456', 101, '12A', 250.00, 'Confirmed', 'Paid', '2023-07-27'),
				  ('AA456', 102, '08C', 180.00, 'Confirmed', 'Paid', '2023-07-28'),
				  ('AF789', 103, '25D', 350.00, 'Confirmed', 'Paid', '2023-07-29'),
				  ('BA123', 104, '10B', 420.00, 'Confirmed', 'Paid', '2023-07-30'),
				  ('DL789', 105, '14F', 310.00, 'Confirmed', 'Paid', '2023-07-31'),
				  ('UA234', 106, '17C', 580.00, 'Confirmed', 'Paid', '2023-08-01'),
				  ('LH567', 107, '23D', 420.00, 'Confirmed', 'Paid', '2023-08-02'),
				  ('EK901', 108, '09A', 380.00, 'Confirmed', 'Paid', '2023-08-03'),
				  ('EK456', 109, '06E', 290.00, 'Confirmed', 'Paid', '2023-08-04'),
				  ('QF678', 110, '15C', 320.00, 'Confirmed', 'Paid', '2023-08-05'),
				  ('EY123', 111, '20F', 410.00, 'Confirmed', 'Paid', '2023-08-06'),
				  ('TK789', 112, '18B', 350.00, 'Confirmed', 'Paid', '2023-08-07'),
				  ('CX456', 113, '11D', 270.00, 'Confirmed', 'Paid', '2023-08-08'),
				  ('AF789', 114, '07A', 460.00, 'Confirmed', 'Paid', '2023-08-09'),
				  ('MH234', 115, '19B', 280.00, 'Pending', 'Unpaid', '2023-08-10'),
				  ('QR567', 116, '22A', 350.00, 'Waitlisted', 'Unpaid', '2023-08-11'),
				  ('EK901', 117, '11F', 420.00, 'Pending', 'Unpaid', '2023-08-12'),
				  ('EK456', 118, '15D', 390.00, 'Cancelled', 'Refunded', '2023-08-13'),
				  ('QF678', 119, '07C', 310.00, 'Waitlisted', 'Unpaid', '2023-08-14'),
				  ('TK789', 120, '08B', 360.00, 'Cancelled', 'Refunded', '2023-08-15'),
				  ('EY123', 121, '25F', 430.00, 'Pending', 'Unpaid', '2023-08-16'),
				  ('CX456', 122, '10A', 300.00, 'Cancelled', 'Refunded', '2023-08-17'),
				  ('AF789', 123, '16C', 260.00, 'Waitlisted', 'Unpaid', '2023-08-18'),
				  ('MH234', 124, '14E', 380.00, 'Cancelled', 'Refunded', '2023-08-19'),
                  ('EK456', 116, '1A', 350.00, 'Confirmed', 'Paid', '2023-03-01');

			
INSERT INTO TravelInsurance (ReservationID, StartDate, EndDate, PhoneNumber)
            VALUES(1000, '2023-03-08', '2023-04-15', 1234567890),
			      (1001, '2023-04-05', '2023-05-12', 9876543210),
				  (1002, '2023-05-15', '2023-05-27', 7894561230),
				  (1003, '2023-06-10', '2023-07-17', 4567891230),
				  (1004, '2023-07-20', '2023-07-30', 3216549870),
				  (1005, '2023-08-12', '2023-08-30', 6541237890),
				  (1006, '2023-09-03', '2023-09-14', 7893216540),
				  (1007, '2023-10-25', '2023-12-01', 8529637410),
				  (1008, '2023-11-15', '2023-11-22', 9638527410),
				  (1009, '2023-12-05', '2023-12-18', 4567891230),
				  (1010, '2024-01-08', '2024-03-31', 9876543210),
				  (1011, '2024-02-12', '2024-03-19', 3216549870),
				  (1012, '2024-03-20', '2024-04-27', 7894561230),
				  (1013, '2024-04-18', '2024-04-28', 8529637410),
				  (1014, '2024-05-10', '2024-06-17', 9638527410),
				  (1015, '2023-05-15', '2023-05-29', 7894561230),
				  (1016, '2023-06-10', '2023-07-17', 4567891230),
				  (1017, '2023-07-20', '2023-08-27', 3216549870),
				  (1018, '2023-08-12', '2023-08-25', 6541237890),
				  (1019, '2023-09-03', '2023-09-19', 7893216540);

   -- ALTERING TABLE TO ADD COMPUTED COLUMN-> `InsuranceCost`
      ALTER TABLE TravelInsurance ADD InsuranceCost AS dbo.CalculateInsuranceCost(ReservationID);

INSERT INTO CoverageDetails (InsurancePolicyNumber, TripCancellation, EmergencyMedical, BaggageLossDelay, TravelDelay, TripInterruption) 
            VALUES(10000, 1, 1, 1, 1, 1),
			      (10001, 0, 1, 1, 0, 0),
				  (10002, 1, 0, 0, 1, 0),
				  (10003, 1, 1, 1, 1, 1),
				  (10004, 1, 0, 1, 0, 1),
				  (10005, 0, 0, 1, 0, 0),
				  (10006, 1, 1, 0, 0, 1),
				  (10007, 0, 1, 0, 1, 1),
				  (10008, 1, 0, 1, 0, 0),
				  (10009, 0, 0, 0, 1, 1),
				  (10010, 1, 1, 0, 1, 0),
				  (10011, 0, 0, 1, 1, 1),
				  (10012, 1, 1, 0, 0, 0),
				  (10013, 0, 1, 1, 1, 0),
				  (10014, 0, 1, 0, 1, 1),
				  (10015, 1, 0, 1, 1, 1),
				  (10016, 0, 0, 1, 1, 0),
				  (10017, 1, 1, 1, 0, 1),
				  (10018, 0, 1, 1, 1, 1),
				  (10019, 1, 0, 0, 1, 0);

/* CARDNUMBER COLUMN IS AN ENCRYPTED COLUMN BELOW */
INSERT INTO PaymentTransaction (ReservationID, PaymentAmount, PaymentMethod, CardNumber, PaymentStatus, TransactionDateTime) 
            VALUES(1000, 1000.00, 'Credit',EncryptByKey(Key_GUID(N'SymmetricKey'),'6144280537131825'),'Paid', '2023-03-01 10:30:00'),
				  (1001, 250.00, 'Debit', EncryptByKey(Key_GUID(N'SymmetricKey'),'6885804701468812'),'Paid', '2023-07-27 11:15:00'),
				  (1002, 180.00, 'Credit', EncryptByKey(Key_GUID(N'SymmetricKey'),'8940203934992852'),'Paid', '2023-07-28 09:45:00'),
				  (1003, 350.00, 'Debit',EncryptByKey(Key_GUID(N'SymmetricKey'),'2042995243361590'), 'Paid', '2023-07-29 14:20:00'), 
				  (1004, 420.00, 'Credit',EncryptByKey(Key_GUID(N'SymmetricKey'),'6119460443911837'),'Paid', '2023-07-30 13:00:00'), 
				  (1005, 310.00, 'Credit',EncryptByKey(Key_GUID(N'SymmetricKey'),'3776126600931619'), 'Paid', '2023-07-31 12:45:00'), 
				  (1006, 580.00, 'Credit',EncryptByKey(Key_GUID(N'SymmetricKey'),'7625405368801363'),'Paid', '2023-08-01 09:30:00'), 
				  (1007, 420.00,'Credit',EncryptByKey(Key_GUID(N'SymmetricKey'),'3206248399923652'),'Paid', '2023-08-02 15:10:00'), 
				  (1008, 380.00, 'Credit',EncryptByKey(Key_GUID(N'SymmetricKey'),'9730187065742873'),'Paid', '2023-08-03 16:00:00'), 
				  (1009, 290.00, 'Credit',EncryptByKey(Key_GUID(N'SymmetricKey'),'4215907198651880'),'Paid', '2023-08-04 14:45:00'), 
				  (1010, 320.00, 'Debit',EncryptByKey(Key_GUID(N'SymmetricKey'),'2133370273920483'),'Paid', '2023-08-05 09:20:00'), 
				  (1011, 410.00, 'Debit',EncryptByKey(Key_GUID(N'SymmetricKey'),'2610210561561012'),'Paid', '2023-08-06 10:00:00'), 
				  (1012, 350.00, 'Credit',EncryptByKey(Key_GUID(N'SymmetricKey'),'1118312844488382'),'Paid', '2023-08-07 11:30:00'), 
				  (1013, 270.00, 'Credit',EncryptByKey(Key_GUID(N'SymmetricKey'),'5293611995046356'),'Paid', '2023-08-08 13:20:00'), 
				  (1014, 460.00,'Debit', EncryptByKey(Key_GUID(N'SymmetricKey'),'5769443928229832'),'Paid', '2023-08-09 16:45:00'),
				  (1015, 280.00,'Credit',EncryptByKey(Key_GUID(N'SymmetricKey'),'7621135375735528'), 'Failed', '2023-08-10 12:32:06'),
				  (1016, 430.00, 'Debit',EncryptByKey(Key_GUID(N'SymmetricKey'),'4164130734992802'),'Failed', '2023-08-16 15:24:07');

INSERT INTO Feedback (ReservationID, PassengerID, FeedbackDate)
            VALUES(1023, 123, '2023-09-18'),
			      (1001, 101, '2023-07-28'),
				  (1015, 115, '2023-08-15'),
				  (1013, 113, '2023-08-20'),
				  (1004, 104, '2023-08-07'),
				  (1008, 108, '2023-08-12'),
				  (1010, 110, '2023-09-18'),
				  (1017, 117, '2023-10-25'),
				  (1011, 111, '2023-09-05'),
				  (1009, 109, '2023-08-15'),
				  (1007, 107, '2023-08-05');

INSERT INTO RedemptionOptions (ProgramID, RedemptionPoints, RedemptionValidity)
            VALUES(1, 1000, '2024-03-31'),
				  (2, 1500, '2024-04-30'),
				  (3, 1200, '2024-05-31'),
				  (4, 1800, '2024-06-30'),
				  (5, 900, '2024-07-31'),
				  (6, 2000, '2024-08-31'),
				  (7, 1100, '2024-09-30'),
				  (8, 2500, '2024-10-31'),
				  (9, 800, '2023-11-30'),
				  (10, 3000, '2024-12-31'),
				  (11, 1400, '2024-01-31'),
				  (12, 1200, '2024-05-31'),
				  (13, 1800, '2024-06-30'),
				  (14, 900, '2023-12-31'),
				  (15, 2000, '2024-08-31');

INSERT INTO ProgramBenefits (ProgramID, BenefitType, BenefitEligibility, BenefitValue)
            VALUES(1, 'Spa/Hotel Credits', 0, 200),
				  (2, 'Loyalty Points', 0, 800),
				  (3, 'Discount Voucher', 1, 500),
				  (4, 'Free Upgrade', 1, 500),
				  (5, 'Lounge Access', 1, 400),
				  (6, 'Priority Boarding', 1, 250),
				  (7, 'Extra Baggage Allowance', 1, 100),
				  (8, 'Complimentary Meals', 1, 150),
				  (9, 'Fast Track Security', 1, 100),
				  (3, 'Discounted Concert tickets', 1, 300),
				  (8, 'Reserved Parking', 0, 150),
				  (3, 'Preferred Seat selection', 1, 100 ),
				  (15, 'Free movie ticket', 0, 200),
				  (10, 'Priority Check-In', 1, 100),
				  (11, 'Exclusive Event Invitations', 0, 200),
				  (12, 'Personal Concierge Service', 0, 100),
				  (13, 'Travel Insurance Coverage', 0, 600),
				  (14, 'Airport Transfer Service', 0, 300),
				  (15, 'Complimentary Wi-Fi', 1, 200);

INSERT INTO Baggage (BaggageWeight, BaggageLength, BaggageHeight,BaggageWidth, BaggageStatus)
            VALUES(20, 20, 20, 15, 'Checked'),
			      (15, 30, 20, 17, 'Checked'),
				  (10, 25, 18, 20, 'Arrived'),
				  (12, 28, 22, 15, 'Checked'),
				  (8, 22, 16,  14, 'Checked'),
				  (18, 32, 24, 15,  'Checked'),
				  (14, 29, 19, 15, 'Checked'),
				  (40, 23, 19, 16, 'Checked'),
				  (20, 35, 26, 18, 'Checked'),
				  (16, 31, 21, 17, 'Checked'),
				  (11, 26, 18, 19,'Checked'),
				  (13, 27, 20, 20,'Checked'),
				  (7, 21, 15, 15,'Checked'),
				  (19, 34, 25, 16, 'Checked'),
				  (48, 33, 20, 15, 'Checked'),
				  (6, 20, 14, 20, 'Checked'),
				  (21, 36, 27, 14,'Checked'),
				  (25, 40, 30, 15, 'Checked'),
				  (23, 38, 28, 15, 'Checked'),
				  (49, 43, 30, 10, 'Checked'),
				  (26, 41, 31, 15,'Checked'),
				  (30, 45, 35, 17,'Checked'),
				  (32, 47, 37, 16,'Checked'),
				  (29, 44, 34, 15, 'Checked'),
				  (27, 42, 32, 20,'Checked'),
				  (36, 51, 39, 18,'Checked'),
				  (34, 49, 38, 15,'Checked'),
				  (31, 46, 36, 16,'Checked'),
				  (38, 53, 41, 17,'Checked'),
				  (33, 48, 37, 16,'Checked'),
				  (35, 50, 40, 18,'Checked');

INSERT INTO BaggageTracking (BaggageID, PassengerID, BaggageTrackingStatus, LastTrackingDate)
            VALUES (900, 100, 'In Transit', '2023-07-27'),
				   (901, 100, 'In Transit', '2023-07-27'),
				   (902, 101, 'Arrived', '2023-07-28'),
				   (903, 102, 'In Transit', '2023-07-29'),
				   (904, 103, 'Delayed', '2023-07-30'),
				   (905, 104, 'In Transit', '2023-07-31'),
				   (906, 105, 'Arrived', '2023-08-01'),
				   (907, 106, 'In Transit', '2023-08-02'),
				   (908, 103, 'Delayed', '2023-08-03'),
				   (909, 108, 'In Transit', '2023-08-04'),
				   (910, 109, 'Arrived', '2023-08-05'),
				   (911, 110, 'In Transit', '2023-08-06'),
				   (912, 111, 'Damaged', '2023-08-07'),
				   (913, 111, 'In Transit', '2023-08-08'),
				   (914, 113, 'On Hold', '2023-08-09'),
				   (915, 114, 'In Transit', '2023-08-10'),
				   (916, 115, 'Arrived', '2023-08-11'),
				   (917, 116, 'In Transit', '2023-08-12'),
				   (918, 117, 'Arrived', '2023-08-13'),
				   (919, 118, 'In Transit', '2023-08-14'),
				   (920, 119, 'Arrived', '2023-08-15'),
				   (921, 120, 'In Transit', '2023-08-16'),
				   (922, 121, 'Arrived', '2023-08-17'),
				   (923, 122, 'In Transit', '2023-08-18'),
				   (924, 123, 'Delayed', '2023-08-19'),
				   (925, 124, 'In Transit', '2023-08-20'),
				   (926, 124, 'Delayed', '2023-08-21'),
				   (927, 122, 'In Transit', '2023-08-22'),
				   (928, 117, 'Arrived', '2023-08-23'),
				   (929, 108, 'In Transit', '2023-08-24'),
				   (930, 115, 'Arrived', '2023-08-25');

INSERT INTO Country (CountryID, CountryName)
            VALUES('USA','United States'),
				  ('FR', 'France'),
				  ('DE', 'Germany'),
				  ('AU', 'Australia'),
				  ('AE', 'United Arab Emirates'),
				  ('SG', 'Singapore'),
				  ('TR' , 'Turkey'),
                  ('HK', 'HongKong'),
                  ('MY' , 'Malaysia'),
                  ('QA', 'Qatar'),
				  ('UK', 'United Kingdom');

INSERT INTO AirlineCompany (AirlineCode, CountryID)
            VALUES ('EK', 'AE'),
			       ('BA', 'UK'),
				   ('AA', 'USA'),
				   ('DL', 'USA'),
				   ('UA', 'USA'),
				   ('LH', 'DE'),
				   ('SQ', 'SG'),
				   ('QF', 'AU'),
				   ('TK', 'TR'),
				   ('EY', 'AE'),
				   ('CX', 'HK'),
				   ('AF', 'FR'),
				   ('MH', 'MY'),
				   ('QR', 'QA');

/************************************************************ VIEWS ************************************************************/

/* VIEW TO LIST THE PASSENGERS WHO ARE ALSO STUDENTS */

CREATE VIEW StudentPassengers AS
SELECT p.PassengerID, 
       s.StudentID, 
	   p.FirstName, 
	   p.LastName, 
	   s.SchoolEmailID
FROM Passenger p
JOIN Student s
  ON p.PassengerID = s.PassengerID;


/* VIEW TO LIST PASSENGER'S FULL NAME, FLIGHT NUMBER, NUMBER OF BAGS, AND BAGGAGE TRACKING STATUS */

CREATE VIEW PassengerBaggageTracking AS
WITH TEMP1 AS (
         SELECT r.PassengerID AS [PassengerID], 
                r.FlightNumber AS [FlightNumber],
				FirstName + ' ' + LastName AS [FullName],
				b.BaggageID,
				b.BaggageTrackingStatus
         FROM Reservation r
		 JOIN Passenger p
		   ON r.PassengerID = p.PassengerID
		 JOIN BaggageTracking b
		   ON p.PassengerID = b.PassengerID),
     TEMP2 AS (
          SELECT PassengerID, 
		         COUNT(BaggageID) AS [NumberOfBags]
		  FROM BaggageTracking
		  GROUP BY PassengerID)
SELECT TEMP1.PassengerID,
       TEMP1.FlightNumber,
	   TEMP1.FullName,
	   TEMP2.NumberOfBags,
	   STRING_AGG(CAST(BaggageID AS varchar) + ' ' + BaggageTrackingStatus, ', ') AS BaggageStatus
FROM TEMP1 
JOIN TEMP2
  ON TEMP1.PassengerID = TEMP2.PassengerID
GROUP BY TEMP1.PassengerID, FlightNumber, FullName, NumberOfBags;


/* VIEW TO SHOW DESTINATION AND ARRIVAL AIRPORT NAMES ALONG WITH OTHER FLIGHT DETAILS*/

CREATE VIEW FlightDetails AS
SELECT f.AirlineCode, f.FlightNumber,ap.AirportName AS [DepartureAirport], a.AirportName AS [DestinationAirport], f.DepartureTime, f.ArrivalTime 
FROM Flight f
LEFT JOIN Airport a
  ON f.DestinationAirport = a.AirportCode
LEFT JOIN Airport ap
  ON f.DepartureAirport= ap.AirportCode;


/********************************************************** DISPLAYING VIEWS *****************************************/

SELECT * FROM PassengerBaggageTracking;
SELECT * FROM StudentPassengers;
SELECT * FROM FlightDetails;

/*==========================================================TEST CASES FOR FUNCTIONS, TRIGGERS, AND CHECK CONSTRAINTS===================================*/
-- The phone number for Airline entity cannot be greater than or less than 10 digits
INSERT INTO Airline(AirlineCode, ProgramID, PhoneNumber, Country, AirlineName) 
            VALUES('QT', 10, 876543210911, 'Qatarxyz', 'Qatar xyz');


-- The phone number for TravelInsurance entity cannot be greater than or less than 10 digits
INSERT INTO TravelInsurance (ReservationID, StartDate, EndDate, PhoneNumber)
            VALUES(1020, '2023-09-03', '2023-09-10', 12345678901);

/* The student won't be able to get any benefit if supporting documents have not been provided. 
This constraint blocks us from adding data to StudentBenefit table if 'SupportingDocument' column has value 0.*/
 INSERT INTO StudentBenefit (GroupBookingID, DiscountPercentage, EnrollmentStatus, SupportingDocumentationProvided
                            ,AirportLoungeAccess, FreeCancellation, DiscountedAirMeals, StudentFareLock, FreeWiFiAccess, ExpiryDate) 
				VALUES(511, 15, 'Enrolled', 0,1, 1, 1, 1, 1, '2023-04-15');

-- Computed columnn to check Insurance cost calculated based on start and end date of insurance. A new column is added to the TravelInsurance table through this.
INSERT INTO TravelInsurance (ReservationID, StartDate, EndDate, PhoneNumber)
            VALUES(1023, '2023-04-08', '2023-09-15', 1234567890);
   -- Checking if a new column is added to the table
   SELECT * FROM TravelInsurance;

-- If baggage weight exceeds 50 lbs, then data won't be added to the baggage table
INSERT INTO Baggage VALUES(55, 32, 18, 18, 'Overweight');




/********************************************** SELECT STATEMENTS TO CHECK DATA IN ALL TABLES **************************************/

SELECT * FROM Airport;
SELECT * FROM LoyaltyProgram;
SELECT * FROM Airline;
SELECT * FROM Flight;
SELECT * FROM Passenger;
SELECT * FROM Reservation;
SELECT * FROM TravelInsurance;
SELECT * FROM CoverageDetails;
SELECT * FROM PaymentTransaction;
SELECT * FROM StudentGroupBooking;
SELECT * FROM Student;
SELECT * FROM StudentBenefit;
SELECT * FROM Feedback;
SELECT * FROM ProgramBenefits;
SELECT * FROM Baggage;
SELECT * FROM BaggageTracking;
SELECT * FROM Country;
SELECT * FROM AirlineCompany;


/*================================================================  HOUSEKEEPING ===========================================================*/
/* Dropping table-level check constraints */
ALTER TABLE Baggage
DROP CONSTRAINT CheckBaggageWeight;

ALTER TABLE StudentBenefit
DROP CONSTRAINT CheckSupportingDocuments;

/* Dropping functions */
DROP FUNCTION CheckBaggageWeightLimit;
DROP FUNCTION CheckStudentSupportingDocument;

/* Dropping views */
DROP VIEW StudentPassengers;
DROP VIEW PassengerBaggageTracking;
DROP VIEW FlightDetails;

/* Dropping Trigger */
DROP TRIGGER CalculateFareBasedOnDiscount;

/* Dropping all tables */

DROP TABLE BaggageTracking;
DROP TABLE Baggage;
DROP TABLE AirlineCompany;
DROP TABLE Country;
DROP TABLE Feedback;
DROP TABLE ProgramBenefits;
DROP TABLE RedemptionOptions;
DROP TABLE Student;
DROP TABLE StudentBenefit;
DROP TABLE StudentGroupBooking;
DROP TABLE PaymentTransaction;
DROP TABLE CoverageDetails;
DROP TABLE TravelInsurance;
DROP TABLE Reservation;
DROP TABLE Passenger;
DROP TABLE Flight;
DROP TABLE Airport;
DROP TABLE Airline;
DROP TABLE LoyaltyProgram;

/* Dropping functions that are being used by tables */
DROP FUNCTION CalculateInsuranceCost;

/* Dropping keys */
-- Close the symmetric key
CLOSE SYMMETRIC KEY SymmetricKey;
-- Drop the symmetric key
DROP SYMMETRIC KEY SymmetricKey;
-- Drop the certificate
DROP CERTIFICATE TestCertificate;
--Drop the DMK
DROP MASTER KEY;


