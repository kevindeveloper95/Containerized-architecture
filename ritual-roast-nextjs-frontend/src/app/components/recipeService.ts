import { useEffect, useState, useCallback } from "react";

// Client-side hook for components that need real-time updates
export const useRecipes = () => {
  const [recipes, setRecipes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [mounted, setMounted] = useState(false);
  const [retryCount, setRetryCount] = useState(0);

  useEffect(() => {
    setMounted(true);
  }, []);

  const fetchRecipes = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);
      
      const controller = new AbortController();
      setTimeout(() => controller.abort(), 10000); // 10 second timeout
      
      const res = await fetch("/api/get_recipe", {
        signal: controller.signal,
        headers: {
          'Content-Type': 'application/json',
        },
      });
      
      if (!res.ok) {
        throw new Error(`Server error: ${res.status} ${res.statusText}`);
      }
      
      const data = await res.json();
      setRecipes(data);
      setError(null);
      setRetryCount(0); // Reset retry count on success
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Unknown error occurred';
      console.error("Error fetching data from Flask:", err);
      setError(errorMessage);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    // Only fetch recipes after component mounts to avoid hydration mismatch
    if (mounted) {
      fetchRecipes();
    }
  }, [mounted, fetchRecipes]);

  const retry = () => {
    setRetryCount(0);
    fetchRecipes();
  };

  return { recipes, loading, error, mounted, retry, retryCount };
};
