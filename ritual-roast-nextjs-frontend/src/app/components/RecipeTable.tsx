"use client";
import React from "react";
import { useRecipes } from "./recipeService";

// Define the recipe type
interface Recipe {
  name: string;
  recipe: string;
  ingredients: string[];
  description: {
    main: string;
    nutrition?: string;
  };
}

const RecipeTable = () => {
  const { recipes, loading, error, mounted, retry, retryCount } = useRecipes();

  // Show loading state until mounted to prevent hydration mismatch
  if (!mounted) {
    return (
      <div className="w-full text-center py-8">
        <div className="flex flex-col items-center space-y-4">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-[color:var(--brown-dark)]"></div>
          <p className="text-[color:var(--brown-dark)]">Loading...</p>
        </div>
      </div>
    );
  }

  // Show loading state
  if (loading) {
    return (
      <div className="w-full text-center py-8">
        <div className="flex flex-col items-center space-y-4">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-[color:var(--brown-dark)]"></div>
          <p className="text-[color:var(--brown-dark)]">
            {retryCount > 0 ? `Retrying... (${retryCount}/2)` : 'Loading recipes...'}
          </p>
        </div>
      </div>
    );
  }

  // Show error state with retry option
  if (error) {
    return (
      <div className="w-full text-center py-8">
        <div className="max-w-md mx-auto bg-red-50 border border-red-200 rounded-lg p-6">
          <div className="text-red-600 mb-4">
            <svg className="mx-auto h-12 w-12 mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16.5c-.77.833.192 2.5 1.732 2.5z" />
            </svg>
            <h3 className="text-lg font-semibold mb-2">Failed to Load Recipes</h3>
            <p className="text-sm text-red-700 mb-4">{error}</p>
          </div>
          
          <div className="space-y-3">
            <button
              onClick={retry}
              disabled={loading}
              className="w-full bg-[color:var(--brown-dark)] text-white px-4 py-2 rounded-md hover:bg-[color:var(--brown)] transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {loading ? 'Retrying...' : 'Try Again'}
            </button>
            
            <div className="text-xs text-gray-500">
              <p>If the problem persists, please check:</p>
              <ul className="mt-1 space-y-1 text-left">
                <li>• Your internet connection</li>
                <li>• Server availability</li>
                <li>• Contact support if needed</li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    );
  }

  // If no recipes, show empty state
  if (!recipes || recipes.length === 0) {
    return (
      <div className="w-full text-center py-8">
        <div className="max-w-md mx-auto bg-gray-50 border border-gray-200 rounded-lg p-6">
          <div className="text-gray-600 mb-4">
            <svg className="mx-auto h-12 w-12 mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
            <h3 className="text-lg font-semibold mb-2">No Recipes Available</h3>
            <p className="text-sm text-gray-700">No recipes have been submitted yet. Be the first to share your favorite dish!</p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div
      className="w-full"
      style={{ fontFamily: "var(--font-montserrat-alternates)" }}
    >
      {/* Desktop and Tablet View */}
      <div className="hidden md:block overflow-x-auto">
        <table className="min-w-full bg-white border-collapse">
          <thead className="bg-[color:var(--brown-dark)] text-white">
            <tr>
              <th className="py-4 px-4 lg:px-8 text-left text-sm lg:text-base font-semibold"></th>
              <th className="py-4 px-4 lg:px-8 text-left text-sm lg:text-base font-semibold"></th>
              <th className="py-4 px-4 lg:px-8 text-left text-sm lg:text-base font-semibold"></th>
              <th className="py-4 px-4 lg:px-8 text-left text-sm lg:text-base font-semibold  md:hidden"></th>
              <th className="py-4 px-4 lg:px-8 text-left text-sm lg:text-base font-semibold  md:hidden"></th>
              <th className="py-4 px-4 lg:px-8 text-left text-sm lg:text-base font-semibold  md:hidden"></th>
              <th className="py-4 px-4 lg:px-8 text-left text-sm lg:text-base font-semibold border-r border-gray-600">
                Name
              </th>
              <th className="py-4 px-4 lg:px-8 text-left text-sm lg:text-base font-semibold border-r border-gray-600">
                Recipe
              </th>
              <th className="py-4 px-4 lg:px-8 text-left text-sm lg:text-base font-semibold border-r border-gray-600">
                Recipe Ingredients
              </th>
              <th className="py-4 px-4 lg:px-8 text-left text-sm lg:text-base font-semibold">
                Recipe Description
              </th>
              <th className="py-4 px-4 lg:px-8 text-left text-sm lg:text-base font-semibold"></th>
              <th className="py-4 px-4 lg:px-8 text-left text-sm lg:text-base font-semibold"></th>
              <th className="py-4 px-4 lg:px-8 text-left text-sm lg:text-base font-semibold"></th>
              <th className="py-4 px-4 lg:px-8 text-left text-sm lg:text-base font-semibold  md:hidden"></th>
              <th className="py-4 px-4 lg:px-8 text-left text-sm lg:text-base font-semibold  md:hidden"></th>
              <th className="py-4 px-4 lg:px-8 text-left text-sm lg:text-base font-semibold  md:hidden"></th>
            </tr>
          </thead>
          <tbody>
            {recipes.map((item: Recipe, index: number) => (
              <tr
                key={index}
                className={`border-b border-gray-200 ${
                  index % 2 === 0
                    ? "bg-[color:var(--table-bg-alt)]"
                    : "bg-[color:var(--table-bg)]"
                }`}
              >
                <td className="py-4 px-4 lg:px-8 text-[color:var(--brown-dark)] align-top"></td>
                <td className="py-4 px-4 lg:px-8 text-[color:var(--brown-dark)] align-top"></td>
                <td className="py-4 px-4 lg:px-8 text-[color:var(--brown-dark)] align-top"></td>
                <td className="py-4 px-4 lg:px-8 text-[color:var(--brown-dark)] align-top  md:hidden"></td>
                <td className="py-4 px-4 lg:px-8 text-[color:var(--brown-dark)] align-top  md:hidden"></td>
                <td className="py-4 px-4 lg:px-8 text-[color:var(--brown-dark)] align-top  md:hidden"></td>
                <td className="py-4 px-4 lg:px-8 font-semibold text-sm lg:text-base text-[color:var(--brown-dark)] align-top border-r border-gray-200">
                  {item.name}
                </td>
                <td className="py-4 px-4 lg:px-8 text-sm lg:text-base text-[color:var(--brown-dark)] align-top border-r border-gray-200">
                  {item.recipe}
                </td>
                <td className="py-4 px-4 lg:px-8 font-semibold text-xs lg:text-sm text-[color:var(--brown-dark)] align-top border-r border-gray-200">
                  <div className="break-words">
                    {item.ingredients.join(" / ")}
                  </div>
                </td>
                <td className="py-4 px-4 lg:px-8 text-xs lg:text-sm text-[color:var(--brown-dark)] align-top">
                  <div className="break-words">
                    <p className="font-semibold">{item.description.main}</p>
                    
                  </div>
                </td>
                <td className="py-4 px-4 lg:px-8 text-[color:var(--brown-dark)] align-top"></td>
                <td className="py-4 px-4 lg:px-8 text-[color:var(--brown-dark)] align-top"></td>
                <td className="py-4 px-4 lg:px-8 text-[color:var(--brown-dark)] align-top"></td>
                <td className="py-4 px-4 lg:px-8 text-[color:var(--brown-dark)] align-top md:hidden"></td>
                <td className="py-4 px-4 lg:px-8 text-[color:var(--brown-dark)] align-top md:hidden"></td>
                <td className="py-4 px-4 lg:px-8 text-[color:var(--brown-dark)] align-top md:hidden"></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Mobile View - Card Layout */}
      <div className="md:hidden space-y-4">
        {recipes.map((item: Recipe, index: number) => (
          <div
            key={index}
            className={`p-4 rounded-lg border ${
              index % 2 === 0
                ? "bg-[color:var(--table-bg-alt)] border-gray-200"
                : "bg-[color:var(--table-bg)] border-gray-200"
            }`}
          >
            <div className="space-y-3">
              <div>
                <h3 className="text-sm font-semibold text-[color:var(--brown-dark)]">
                  Name
                </h3>
                <p className="text-sm text-[color:var(--brown-dark)]">
                  {item.name}
                </p>
              </div>
              <div>
                <h3 className="text-sm font-semibold text-[color:var(--brown-dark)]">
                  Recipe
                </h3>
                <p className="text-sm text-[color:var(--brown-dark)]">
                  {item.recipe}
                </p>
              </div>
              <div>
                <h3 className="text-sm font-semibold text-[color:var(--brown-dark)]">
                  Recipe Ingredients
                </h3>
                <p className="text-xs text-[color:var(--brown-dark)]">
                  {item.ingredients.join(" / ")}
                </p>
              </div>
              <div>
                <h3 className="text-sm font-semibold text-[color:var(--brown-dark)]">
                  Recipe Description
                </h3>
                <p className="text-xs text-[color:var(--brown-dark)]">
                  {item.description.main}
                </p>
               
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default RecipeTable;
