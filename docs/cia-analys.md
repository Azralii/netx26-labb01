# CIA-analys – Begränsad inputvalidering

## Valt hot/risk

Jag har valt risken **begränsad inputvalidering** i `app/main.py`.

Programmet kontrollerar att `service_name` inte är tomt och att det är en sträng. Däremot kontrolleras inte maximal längd eller att innehållet följer ett bestämt format.

## Konfidentialitet

Risken påverkar konfidentialiteten i begränsad omfattning. Om felaktig input i en större applikation leder till oväntat beteende kan det i vissa situationer bidra till att information exponeras.

I den nuvarande enkla labbapplikationen ser jag ingen direkt exponering av känslig information.

## Integritet / riktighet

Risken kan påverka integriteten eftersom programmet accepterar strängar utan att kontrollera att innehållet följer ett förväntat format.

Om felaktiga värden används kan information bli missvisande eller felaktig.

En möjlig åtgärd är därför att införa tydligare regler för vilka värden som accepteras.

## Tillgänglighet

Tillgängligheten kan påverkas om applikationen i en större miljö tar emot mycket stora eller oväntade värden.

Programmet har ingen maximal längd för `service_name`. En rimlig maxlängd skulle därför kunna minska risken för onödig resursbelastning.

## Sammanfattning

Den största påverkan av denna risk bedömer jag vara **integritet/riktighet och tillgänglighet**. Konfidentialiteten påverkas mindre direkt.

Eftersom `main.py` är en enkel demoapp fungerar koden för labbens syfte. I en produktionsmiljö skulle inputvalideringen behöva vara mer omfattande.

