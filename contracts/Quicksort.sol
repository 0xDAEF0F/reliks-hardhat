// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract QuickSort {
    function sort(uint256[] storage data) internal {
        quickSort(data, int256(0), int256(data.length - 1));
    }

    function quickSort(
        uint256[] storage arr,
        int256 left,
        int256 right
    ) private {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        uint256 pivot = arr[uint256(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint256(i)] > pivot) i++;
            while (pivot > arr[uint256(j)]) j--;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (
                    arr[uint256(j)],
                    arr[uint256(i)]
                );
                i++;
                j--;
            }
        }
        if (left < j) quickSort(arr, left, j);
        if (i < right) quickSort(arr, i, right);
    }
}
