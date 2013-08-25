"""
Unit tests for the Inventory class.
"""
import unittest
import copy
from datetime import date

from beancount.core.amount import Amount
from beancount.core.inventory import Inventory


class TestInventory(unittest.TestCase):

    def checkAmount(self, inventory, number, currency):
        amount = Amount(number, currency)
        inv_amount = inventory.get_amount(amount.currency)
        self.assertEqual(inv_amount , amount)

    def test_ctor(self):
        inv = Inventory()
        self.assertTrue(inv.is_empt())

## FIXME: ctor with positions




    def test_copy(self):
        inv = Inventory()
        inv.add(Amount('100.00', 'USD'))
        self.checkAmount(inv, '100', 'USD')

        # Test copying.
        inv2 = copy.copy(inv)
        inv2.add(Amount('50.00', 'USD'))
        self.checkAmount(inv2, '150', 'USD')

        # Check that the original object is not modified.
        self.checkAmount(inv, '100', 'USD')

    def test_add(self):
        inv = Inventory()
        inv.add(Amount('100.00', 'USD'))
        self.checkAmount(inv, '100', 'USD')

        # Add some amount
        inv.add(Amount('25.01', 'USD'))
        self.checkAmount(inv, '125.01', 'USD')

        # Subtract some amount.
        inv.add(Amount('-12.73', 'USD'))
        self.checkAmount(inv, '112.28', 'USD')

        # Subtract some to be negative (should be allowed if no lot).
        inv.add(Amount('-120', 'USD'))
        self.checkAmount(inv, '-7.72', 'USD')

        # Subtract some more.
        inv.add(Amount('-1', 'USD'))
        self.checkAmount(inv, '-8.72', 'USD')

        # Add to above zero again
        inv.add(Amount('18.72', 'USD'))
        self.checkAmount(inv, '10', 'USD')

    def test_add_multi_currency(self):
        inv = Inventory()
        inv.add(Amount('100', 'USD'))
        inv.add(Amount('100', 'CAD'))
        self.checkAmount(inv, '100', 'USD')
        self.checkAmount(inv, '100', 'CAD')

        inv.add(Amount('25', 'USD'))
        self.checkAmount(inv, '125', 'USD')
        self.checkAmount(inv, '100', 'CAD')

    def test_add_withlots(self):
        # Testing the strict case where everything matches, with only a cost.
        inv = Inventory()
        inv.add(Amount('50', 'GOOG'), Amount('700', 'USD'))
        self.checkAmount(inv, '50', 'GOOG')

        inv.add(Amount('-40', 'GOOG') , Amount('700', 'USD'))
        self.checkAmount(inv, '10', 'GOOG')

        self.assertRaises(ValueError, inv.add, Amount('-12', 'GOOG'), Amount('700', 'USD'))

        # Testing the strict case where everything matches, a cost and a lot-date.
        inv = Inventory()
        inv.add(Amount('50', 'GOOG'), Amount('700', 'USD'), date(2000, 1, 1))
        self.checkAmount(inv, '50', 'GOOG')

        inv.add(Amount('-40', 'GOOG') , Amount('700', 'USD'), date(2000, 1, 1))
        self.checkAmount(inv, '10', 'GOOG')

        self.assertRaises(ValueError, inv.add, Amount('-12', 'GOOG'), Amount('700', 'USD'), date(2000, 1, 1))

    def __test_get_costs(self):
        inv = Inventory()
        inv.add(Amount('10.00', 'USD'), Amount('1.05', 'CAD'))
        print(inv.get_amounts())
        print(inv.get_costs())

        inv = Inventory()
        inv.add(Amount('100', 'AAPL'), Amount('404.00', 'USD'))
        print(inv.get_amounts())
        print(inv.get_costs())
# FIXME: We need real checks here instead of just prints.





# FIXME: Test a conversion of shares with lot-date, e.g.:
#
#   2000-01-18 * Buy CRA
#     Assets:CA:RBC-Investing:Taxable-CAD:CRA           4 "CRA1" {232.00 USD / 2000-01-18}
#     Assets:CA:RBC-Investing:Taxable-CAD               -1395.43 CAD @ 0.665027984206 USD  ; cost
#
#   2000-02-22 * CRA Stock Split 2:1
#     Assets:CA:RBC-Investing:Taxable-CAD:CRA          -4 "CRA1" {232.00 USD / 2000-01-18}
#     Assets:CA:RBC-Investing:Taxable-CAD:CRA           8 CRA {116.00 USD / 2000-01-18}
#


    def test_negative(self):
        inv = Inventory()
        inv.add(Amount('10', 'USD'))
        ninv = -inv
        self.checkAmount(ninv, '-10', 'USD')

    def test_sum_inventories(self):
        inv1 = Inventory()
        inv1.add(Amount('10', 'USD'))

        inv2 = Inventory()
        inv2.add(Amount('20', 'CAD'))
        inv2.add(Amount('55', 'GOOG'))

        inv = inv1 + inv2



## FIXME: remove
unittest.main()