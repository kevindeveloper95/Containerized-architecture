"use client";
import { useState, useCallback } from "react";
import OurChoices from "./components/OurChoices";
import RecipeTable from "./components/RecipeTable";
import RecipeForm from "./components/RecipeForm";
import Banner from "./components/Banner";
import CountdownTimer from "./components/CountdownTimer";


export default function Home() {
  const [refreshKey, setRefreshKey] = useState(0);

  const handleRecipeSubmitted = useCallback(() => {
    // Increment the refresh key to trigger a re-render of RecipeTable
    setRefreshKey(prev => prev + 1);
  }, []);

  return (
    <main>
      <Banner />
      <CountdownTimer />
      <RecipeForm onRecipeSubmitted={handleRecipeSubmitted} />
      <RecipeTable key={refreshKey} />
      <OurChoices />  
      {/* <RecipeTables /> */}
    </main>
  );
}

